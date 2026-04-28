import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ACCOUNTS/order_list.dart';
import 'package:beposoft/pages/ACCOUNTS/update_order_products.dart';
import 'package:beposoft/pages/api.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class OrderReview extends StatefulWidget {
  final id;
  final customer;
  const OrderReview({super.key, required this.id, required this.customer});

  @override
  State<OrderReview> createState() => _OrderReviewState();
}

class _OrderReviewState extends State<OrderReview> {
  Drawer d = Drawer();
  var ord;
  bool showAllGrv = false;

  List<Map<String, dynamic>> warehouse = [];
// Add to your State class
  bool showPayStatusDropdown = false;
  String? selectedPayStatus;
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> bank = [];
  String? selectedBank;
  String? createdBy;
  String? companyname;
  DateTime selectedDate = DateTime.now();
  DateTime selectedDate2 = DateTime.now();
  bool showFamilyDropdown = false;
  bool showCompanyDropdown = false;
  String? cod_status;
  bool showParcelNoteField = false;
  String? advance_cod;
  double approvedGrvAmount = 0.0;
  double refundReceiptAmount = 0.0;
  Map<String, dynamic>? selectedCustomer;
  List<Map<String, dynamic>> filteredCustomers = [];
  bool customersLoaded = false;
  Map<String, dynamic>? tempSelectedCustomer;
  double approvedCodReturnAmount = 0.0;
  int currentPage = 1;
  int totalPages = 1;
  String searchQuery = "";
  bool showParcelServiceDropdown = false;
  final TextEditingController parcelServiceNoteController =
      TextEditingController();

  String? currentOrderStatus; // REAL status from API
  bool statusSubmitted = false; // Track submit action
  String normalizePayStatus(String? value) {
    if (value == null) return "";
    return value.toLowerCase().trim();
  }

  String? mapPayStatus(String? value) {
    if (value == null) return null;
    value = value.toLowerCase().trim();

    if (value == "paid") return "paid";
    if (value == "cod") return "COD";
    if (value == "credit") return "credit";

    return null; // do NOT return empty string
  }

  bool showPaymentMethodDropdown = false;
  bool showCodTypeDropdown = false;
  List<Uint8List> selectedImageslist = [];
  String? selectedCompany;
  TextEditingController amountController = TextEditingController();
  TextEditingController transactionIdController = TextEditingController();
  TextEditingController remarkController = TextEditingController();
  TextEditingController receivedDateController = TextEditingController();
  TextEditingController advanceController = TextEditingController();
  String? selectedStatus;
  String? beforeStatus;
  String? notebefore;
  List<Map<String, dynamic>> ledgerEntries = [];
  List<Map<String, dynamic>> filteredEntries = [];
  double totalDebit = 0.0;
  double totalCredit = 0.0;
  final TextEditingController noteController = TextEditingController();
  TextEditingController actualweightController = TextEditingController();
  TextEditingController postofficeamountController = TextEditingController();
  TextEditingController shippingchargeController = TextEditingController();
  TextEditingController codamount = TextEditingController();
  TextEditingController shippingmethod = TextEditingController();
  TextEditingController trackingIdController = TextEditingController();
  TextEditingController accountsnoteController = TextEditingController();
  List<Map<String, dynamic>> selectedImageData =
      []; // Replace your previous selectedImageUrls list

  List<String> paystatus = ["paid", 'COD', 'credit'];
  List<String> codtype = ["select type", "FULL_COD", 'PARTIAL_COD', 'null'];

  var selectedserviceId;
  List<String> statuses = [];
  List<String> statuses2 = [
    'Invoice Created',
    'Invoice Approved',
    'Waiting For Confirmation',
    'To Print',
    'Packing under progress',
    'Packed',
    'Ready to ship',
    'Shipped',
    'Invoice Rejected',
  ];

  List<String> statuses3 = [];

  bool isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    initData();
    getbank();
    getcourierservices();
    fetchCustomerLedgerDetails();
    getfamily();
    getcompany();
    receivedDateController.text = DateFormat('dd-MM-yyyy').format(selectedDate);
    // print(widget.id);
  }

  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> products = [];
  var dep;
  var warehousee;
  var department;
  Future<void> initData() async {
    await fetchOrderItems();
    getcustomer();

    dep = await getdepFromPrefs();
    department = dep;

    warehousee = await getwarehouseFromPrefs();
    await fetchProductListid(warehouse);
    await getimage();

    // Ensure the current status is in the list
    if (selectedStatus != null && !statuses.contains(selectedStatus)) {
      statuses.insert(0, selectedStatus!);
    }

    setState(() {
      filteredProducts = products;
    });
  }

  bool showAllProducts = false;
  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getwarehouseFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? warehouseId = prefs.getInt('warehouse');

    // Check if warehouseId is null before converting to String
    return warehouseId?.toString();
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  var kAllStatuses = <String>[
    'Invoice Approved',
    'Waiting For Confirmation',
    'To Print',
    'Packing under progress',
    'Packed', // 👈 use either "Packed" or "Packing" everywhere; be consistent
    'Ready to ship',
    'Shipped',
    'Invoice Rejected',
  ];

  final Map<String, List<String>> statusFlow = {
    'Invoice Created': [
      'Invoice Created',
      'Invoice Approved',
      'Invoice Rejected',
    ],
    'Invoice Approved': [
      'Invoice Approved',
      'Waiting For Confirmation',
      'Invoice Rejected',
    ],
    'Waiting For Confirmation': [
      'Waiting For Confirmation',
      'To Print',
      'Invoice Rejected',
    ],
    'To Print': [
      'To Print',
      'Packing under progress',
      'Invoice Rejected',
    ],
    'Packing under progress': [
      'Packing under progress',
      'Packed',
      'Invoice Rejected',
    ],
    'Packed': [
      'Packed',
      'Ready to ship',
      'Invoice Rejected',
    ],
    'Ready to ship': [
      'Ready to ship',
      'Shipped',
      'Invoice Rejected',
    ],
    'Shipped': [
      'Shipped',
    ],
    'Invoice Rejected': [
      'Invoice Rejected',
    ],
  };

  List<String> getFilteredStatuses() {
    // 🔥 CEO / COO → ALL statuses
    if (isTopManagement()) {
      return statuses2;
    }

    // 🔹 ADMIN / ACCOUNTS
    if (isAdminOrAccounts()) {
      if (currentOrderStatus == null) return [];

      final currentIndex = statuses2.indexOf(currentOrderStatus!);
      final List<String> result = [];

      // Always add current (before submit only)
      if (!statusSubmitted) {
        result.add(currentOrderStatus!);
      }

      // Add next status if exists
      if (currentIndex != -1 && currentIndex + 1 < statuses2.length) {
        result.add(statuses2[currentIndex + 1]);
      }

      // 🔥 ALWAYS add Invoice Rejected (once)
      if (!result.contains('Invoice Rejected')) {
        result.add('Invoice Rejected');
      }

      return result;
    }

    // 🔹 Other departments → unchanged
    return statusFlow[selectedStatus] ?? [selectedStatus ?? statuses2.first];
  }

  var customerledgertotal;
  var customerledgerreceived;
  var difference;
  bool ledger = false;
  Future<void> getimage() async {
    final token = await gettoken();
    try {
      final response = await http.get(
        Uri.parse('$api/api/order/payment/images/${widget.id}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var imagesData = parsed['images'] as List<dynamic>;

        List<Map<String, dynamic>> tempImages = [];

        for (var img in imagesData) {
          tempImages.add({
            'id': img['id'],
            'imageUrl': '$api${img['image']}',
          });
        }

        setState(() {
          selectedImageData = tempImages;
        });
      }
    } catch (e) {}
  }

  Future<void> deleteimage(var Id) async {
    try {
      final token = await getTokenFromPrefs();

      ;
      var response = await http.delete(
        Uri.parse('$api/api/order/payment/images/delete/${Id}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image deleted successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green, // ✅ Green background
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red, // ❌ Red background
          ),
        );
      }
      fetchOrderItems();
      getimage();
    } catch (error) {
      ;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating shipping charge'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> deleteboxlog(BuildContext scaffoldContext, var box) async {
    final token = await gettoken();
    try {
      final response = await http.post(
        Uri.parse('$api/api/datalog/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'before_data': {"status": "Box deleted"},
          'after_data': {"status": "Count: ${box}"},
          'order': widget.id,
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

  Future<void> Addnotelog(BuildContext scaffoldContext, int orderId) async {
    final token = await getTokenFromPrefs();
    try {
      final response = await http.post(
        Uri.parse('$api/api/datalog/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'before_data': {"status": "$notebefore"},
          'after_data': {"status": noteController.text},
          'order': orderId,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('note log added Successfully.'),
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

  void addimages(BuildContext context) async {
    final token = await getTokenFromPrefs();

    try {
      var uri = Uri.parse('$api/api/order/payment/images/upload/');
      var request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add other fields
      request.fields['order'] = widget.id.toString();
      request.fields['uploaded_at'] =
          DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Add files
      for (var bytes in selectedImageslist) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'images', // field name
            bytes, // Uint8List
            filename:
                '${DateTime.now().millisecondsSinceEpoch}.jpg', // give a name
            contentType: http.MediaType('image', 'jpeg'),
          ),
        );
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 201) {
        getimage();
        setState(() {
          selectedImageslist.clear(); // Clear the list after successful upload
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color.fromARGB(255, 49, 212, 4),
            content: Text('Success!'),
          ),
        );
      } else {
        throw Exception('Upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Image size should be less than 1.5MB'),
        ),
      );
    }
  }

  Future<Uint8List> readBytesSafely(XFile file) async {
    final stream = file.openRead();
    final builder = BytesBuilder();

    await for (final chunk in stream) {
      builder.add(chunk);
    }

    return builder.toBytes();
  }

  final ImagePicker picker = ImagePicker();
  Future<void> selectMultipleImages() async {
    try {
      final List<XFile>? picked = await picker.pickMultiImage(
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 90,
      );

      if (picked == null || picked.isEmpty) return;

      List<Uint8List> finalBytes = [];

      for (var img in picked) {
        // SAF-SAFE bytes reading
        Uint8List bytes = await readBytesSafely(img);

        // 👇👇 ADD THIS PRINT HERE

        finalBytes.add(bytes);
      }

      setState(() {
        selectedImageslist = finalBytes;
      });
    } catch (e) {}
  }

  Future<File?> compressImageToTargetSize(
      File file, int targetSizeInBytes) async {
    int quality = 90;
    final dir = await getTemporaryDirectory();
    String targetPath =
        path.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

    File? result;

    while (quality > 10) {
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
      );

      if (compressed != null &&
          await compressed.length() <= targetSizeInBytes) {
        result = File(compressed.path); // ✅ Explicitly convert XFile to File
        break;
      }

      quality -= 5; // reduce quality gradually
    }

    return result;
  }

  List<String> statusesForDept(String? depRaw) {
    final dep = (depRaw ?? '').trim().toLowerCase();
    if (dep == 'bdm') {
      return ['Invoice Approved', 'Invoice Rejected'];
    } else if (dep == 'accounts / accounting') {
      return ['Shipped', 'Waiting For Confirmation', 'Invoice Rejected'];
    } else if (dep == 'admin') {
      return ['To Print', 'Invoice Rejected'];
    } else if (dep == 'warehouse') {
      return ['Packing under progress', 'Packed', 'Ready to ship'];
    } else if (dep == 'coo') {
      // ✅ COO sees ALL
      return List<String>.from(kAllStatuses);
    }
    // default (others) → ALL
    return List<String>.from(kAllStatuses);
  }

// 3) Your filtering logic, with an override to show everything (for COO)
// List<String> getFilteredStatuses(
//   String? selectedStatus,
//   List<String> availableStatuses, {
//   bool showAll = false,
// }) {
//   if (showAll) {
//     // COO: return everything as-is
//     return List<String>.from(availableStatuses);
//   }

//   List<String> filteredStatuses;
//   if (selectedStatus != null && availableStatuses.contains(selectedStatus)) {
//     final index = availableStatuses.indexOf(selectedStatus);
//     final endIndex = (index + 2 <= availableStatuses.length) ? index + 2 : availableStatuses.length;
//     filteredStatuses = availableStatuses.sublist(index, endIndex);
//   } else {
//     filteredStatuses = List<String>.from(availableStatuses);
//   }

//   // Ensure selectedStatus is present
//   if (selectedStatus != null && !filteredStatuses.contains(selectedStatus)) {
//     filteredStatuses.insert(0, selectedStatus);
//   }

//   // Always include "Invoice Rejected"
//   if (!filteredStatuses.contains('Invoice Rejected')) {
//     filteredStatuses.add('Invoice Rejected');
//   }

//   // De-duplicate just in case
//   return filteredStatuses.toSet().toList();
// }
  List<Map<String, dynamic>> fam = [];
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
              'created_user': productData['created_user'],
              'family': familyNames, // Add family names here
              'image': productData['image'], // Main product image
              'locked_stock': productData['locked_stock'],
              // Don't process single_products or variant_products
            });
          }

          setState(() {
            products = productList;
            filteredProducts = products;
          });
        }
      }
    } catch (error) {}
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

      List<Map<String, dynamic>> familylist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          String imageUrl = "${productData['image']}";
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

  var balanceledger;
  void calculatebalance() {
    balanceledger = Balance - customerledgerreceived;
  }

  Future<void> fetchCustomerLedgerDetails() async {
    try {
      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/customer/${widget.customer}/ledger/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        final ledgerList = parsed['data']['ledger'] as List<dynamic>? ?? [];
        final advanceReceipts =
            parsed['data']['advance_receipts'] as List<dynamic>? ?? [];
        final paymentReceipts =
            parsed['data']['payment_receipts'] as List<dynamic>? ?? [];
        final refundReceipts =
            parsed['data']['refund_receipts'] as List<dynamic>? ?? [];
        final grvList = parsed['data']['grv'] as List<dynamic>? ?? [];

        /// 🔹 Transfers
        final ledgerSentTransfers =
            parsed['data']['ledger_sent_transfers'] as List<dynamic>? ?? [];
        final advanceTransfers =
            parsed['data']['advance_transfers'] as List<dynamic>? ?? [];

        double totalAmountSum = 0.0;
        double receivedPaymentSum = 0.0;
        double approvedGrvSum = 0.0;
        double refundReceiptSum = 0.0;
        double advanceTransferSum = 0.0;

        /// 1️⃣ Ledger total (orders)
        for (var order in ledgerList) {
          final status = order['status']?.toString();

          if (status != 'Invoice Created' && status != 'Invoice Rejected') {
            totalAmountSum +=
                (order['total_amount'] as num?)?.toDouble() ?? 0.0;
          }
        }

        /// 2️⃣ Payment receipts (DEBIT)
        for (var payment in paymentReceipts) {
          receivedPaymentSum +=
              double.tryParse(payment['amount']?.toString() ?? '0') ?? 0.0;
        }

        /// 3️⃣ Advance receipts (DEBIT)
        for (var adv in advanceReceipts) {
          receivedPaymentSum +=
              double.tryParse(adv['amount']?.toString() ?? '0') ?? 0.0;
        }

        /// 4️⃣ Ledger sent transfers (DEBIT)
        for (var transfer in ledgerSentTransfers) {
          totalAmountSum +=
              double.tryParse(transfer['amount']?.toString() ?? '0') ?? 0.0;
        }

        /// 5️⃣ Approved GRV (DEBIT / adjustment)
        for (var grv in grvList) {
          final status = grv['status']?.toString().toLowerCase();
          if (status == 'approved') {
            approvedGrvSum +=
                double.tryParse(grv['price']?.toString() ?? '0') ?? 0.0;
          }
        }

        /// 6️⃣ Refund receipts (CREDIT)
        for (var refund in refundReceipts) {
          refundReceiptSum +=
              double.tryParse(refund['amount']?.toString() ?? '0') ?? 0.0;
        }

        /// 7️⃣ Advance transfers (CREDIT)
        for (var advTransfer in advanceTransfers) {
          advanceTransferSum +=
              double.tryParse(advTransfer['amount']?.toString() ?? '0') ?? 0.0;
        }

        /// 🔥 Apply CREDIT / DEBIT adjustments
        totalAmountSum += refundReceiptSum;
        totalAmountSum += advanceTransferSum;

        receivedPaymentSum += approvedGrvSum;

        /// 8️⃣ Difference logic
        double dif;
        if (receivedPaymentSum > totalAmountSum) {
          dif = receivedPaymentSum - totalAmountSum;
          ledger = true; // company owes customer
        } else {
          dif = totalAmountSum - receivedPaymentSum;
          ledger = false; // customer owes company
        }

        setState(() {
          customerledgertotal = totalAmountSum;
          customerledgerreceived = receivedPaymentSum;
          difference = dif;

          approvedGrvAmount = approvedGrvSum;
          refundReceiptAmount = refundReceiptSum;
        });

        calculatebalance();
      }
    } catch (e) {
      // optional error handling
    }
  }

  void showParcelServiceDialog(
      BuildContext context, var id, dynamic currentParcelServiceId) {
    selectedserviceId = currentParcelServiceId != null
        ? int.tryParse(currentParcelServiceId.toString())
        : null;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Select Parcel Service'),
              content: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1.0),
                ),
                child: DropdownButton<int>(
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: const Text('Select a Parcel Service'),
                  value: courierdata.any(
                    (item) =>
                        item['id'].toString() == selectedserviceId?.toString(),
                  )
                      ? int.tryParse(selectedserviceId.toString())
                      : null,
                  items: courierdata.map<DropdownMenuItem<int>>((item) {
                    return DropdownMenuItem<int>(
                      value: int.tryParse(item['id'].toString()),
                      child: Text(
                        item['name']?.toString() ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (int? value) {
                    setDialogState(() {
                      selectedserviceId = value;
                    });

                    setState(() {
                      selectedserviceId = value;
                    });
                  },
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    if (selectedserviceId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select parcel service'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final success = await updateparcel(selectedserviceId, id);

                    if (success && Navigator.canPop(dialogContext)) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showShippingChargeDialog(
      BuildContext context, Map<String, dynamic> boxDetails) {
    final shippingController = TextEditingController(
        text: boxDetails['shipping_charge']?.toString() ?? '');
    final actualWeightController = TextEditingController(
        text: boxDetails['actual_weight']?.toString() ?? '');
    final postOfficeAmountController = TextEditingController(
        text: boxDetails['parcel_amount']?.toString() ?? '');
    final dateController = TextEditingController(
        text: boxDetails['postoffice_date']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Box Details'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // Shipping Charge

                SizedBox(height: 10),
                // Actual Weight
                TextField(
                  controller: actualWeightController,
                  decoration: InputDecoration(
                    labelText: 'Actual Weight',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                // Post Office Amount
                TextField(
                  controller: postOfficeAmountController,
                  decoration: InputDecoration(
                    labelText: 'Post Office Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                // Date Picker
                TextField(
                  controller: dateController,
                  decoration: InputDecoration(
                    labelText: 'Select Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );

                    if (pickedDate != null) {
                      dateController.text =
                          "${pickedDate.toLocal()}".split(' ')[0];
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (actualWeightController.text.isNotEmpty &&
                    postOfficeAmountController.text.isNotEmpty &&
                    dateController.text.isNotEmpty) {
                  AddStatusTime2(context, boxDetails['box']);
                  updateactualweight(
                    boxDetails['id'],

                    double.parse(actualWeightController.text),
                    double.parse(postOfficeAmountController.text),
                    dateController.text, // Pass selected date
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill out all fields.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // final List<String> statuses = [
  //   'Pending',
  //   'Approved',
  //   'Invoice Created',
  //   'Invoice Approved',
  //   'Waiting For Confirmation',
  //   'To Print',
  //   'Invoice Rejectd',
  //   'Processing',
  //   'Refunded',
  //   'Return',
  //   'Completed',
  //   'Cancelled',
  //   'Shipped'
  // ];
  double netAmountBeforeTax = 0.0; // Define at the class level

  double updateamount = 0.0; // Define at the class level

  double totalTaxAmount = 0.0; // Define at the class level
  double payableAmount = 0.0; // Define at the class level
  double Balance = 0.0; // Define at the class level
  double paymentreceipt = 0.0; // Define at the class level
  int? selectedAddressId; // Variable to store the selected address ID
  bool showBankDropdown = false;
  var selectedfamily;
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
        receivedDateController.text =
            DateFormat('dd-MM-yyyy').format(selectedDate);
      });
    }
  }

  Future<void> updateordercodtype() async {
    try {
      String? codStatusToSend;

      if (cod_status == "select type") {
        codStatusToSend = null;
      } else {
        codStatusToSend = cod_status;
      }
      final token = await gettoken();

      var response = await http.put(
        Uri.parse('$api/api/orders/update/${widget.id}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'cod_status': codStatusToSend,
          },
        ),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Address updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  OrderReview(id: widget.id, customer: widget.customer)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to update cod type'),
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

  Future<void> updateboxstatus(var orderId) async {
    try {
      final token = await getTokenFromPrefs();
      var response = await http.put(
        Uri.parse('$api/api/warehouse/detail/$orderId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'status': selectedStatus,
          },
        ),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shipping charge updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        fetchOrderItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update shipping charge'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating shipping charge'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void showStatusDialog(BuildContext context, var order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                hint: Text('Select Status'),
                items: statuses.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStatus =
                        value; // This will store the selected status
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    AddStatusTime(context);
                    await updateboxstatus(order['id']);
                    Navigator.of(context)
                        .pop(); // Close the dialog after saving
                  },
                  label: Text("Save"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Button color
                    foregroundColor: Colors.white, // Text color
                  ),
                  icon: Icon(Icons.save),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> courierdata = [];

  Future<void> getcourierservices() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/parcal/service/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Ensure the response is in the expected format
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        // Access the 'data' field which contains the list of courier services
        List<Map<String, dynamic>> Courierlist = [];

        // Check if 'data' exists in the response
        if (parsed.containsKey('data')) {
          for (var productData in parsed['data']) {
            Courierlist.add({
              'id': productData['id'],
              'name': productData['name'],
            });
          }
        }

        setState(() {
          courierdata = Courierlist;
        });
        ;
      }
    } catch (error) {}
  }

  String getCourierName(dynamic parcelServiceId) {
    if (parcelServiceId == null) return 'Select Parcel Service';

    final matched = courierdata.where(
      (e) => e['id'].toString() == parcelServiceId.toString(),
    );

    if (matched.isEmpty) return parcelServiceId.toString();

    return matched.first['name']?.toString() ?? parcelServiceId.toString();
  }

  Future<void> updateOrderParcelDetails() async {
    try {
      final token = await getTokenFromPrefs();

      final body = {
        'parcel_service': selectedserviceId,
        'parcel_service_note': parcelServiceNoteController.text.trim(),
      };

      final response = await http.put(
        Uri.parse('$api/api/orders/update/${widget.id}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        await fetchOrderItems();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parcel service updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update parcel service'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Parcel update error: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating parcel service'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> SendTrackingId(
      BuildContext scaffoldContext, var trackingId, var Orderid) async {
    final token = await gettoken();
    try {
      final response = await http.post(Uri.parse('$api/api/sendtrackingid/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'name': ord['customer']['name'],
            'tracking_id': trackingId,
            'order_id': Orderid,
            'phone': ord['customer']['phone'],
          }));
      ;
      ;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Tracking Id Sent Successfully.'),
          ),
        );
        // Navigator.push(
        //     context, MaterialPageRoute(builder: (context) => OrderReview()));
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Sending Tracking Id failed.'),
          ),
        );
      }
    } catch (e) {
      ;
    }
  }

  Future<void> AddStatusTime(BuildContext scaffoldContext) async {
    final token = await gettoken();
    try {
      final response = await http.post(
        Uri.parse('$api/api/datalog/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'before_data': {"status": beforeStatus},
          'after_data': {"status": selectedStatus},
          'order': widget.id,
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

  Future<void> AddStatusTime2(BuildContext scaffoldContext, var box) async {
    final token = await gettoken();
    try {
      final response = await http.post(
        Uri.parse('$api/api/datalog/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'before_data': {"status": "Created ${box}"},
          'after_data': {"status": "Updated Post office data of ${box}"},
          'order': widget.id,
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

  Future<void> AddStatusTime3(BuildContext scaffoldContext) async {
    final token = await gettoken();
    try {
      final response = await http.post(
        Uri.parse('$api/api/datalog/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'before_data': {"status": "Recipt"},
          'after_data': {
            "status": "Recipt of amount ${amountController.text} is Created"
          },
          'order': widget.id,
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

  Future<void> updatenote() async {
    try {
      final token = await getTokenFromPrefs();

      final jwt = JWT.decode(token!);
      var id = jwt.payload['id']; // Expected to be an int
      String formattedTime = DateFormat("HH:mm").format(DateTime.now());
      final isToPrint =
          (selectedStatus ?? '').toString().trim().toLowerCase() == 'to print';
      Map<String, dynamic> body = {};

      if (noteController.text.trim().isNotEmpty) {
        body['note'] = noteController.text.trim().isNotEmpty
            ? noteController.text
            : 'nothing';
      }

      var response = await http.put(
        Uri.parse('$api/api/shipping/${widget.id}/order/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        fetchOrderItems();
        Addnotelog(context, widget.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('status updated successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green, // Add green background color
          ),
        );
        //  Navigator.pushReplacement(
        //       context,
        //       MaterialPageRoute(builder: (context) => OrderList(status:null)),
        //     );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red, // Add red background color
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

  bool isRackSelected() {
    if (items.isEmpty) return false;

    for (var item in items) {
      final rack = item['rack_details'];
      if (rack != null && rack is List && rack.isNotEmpty) {
        return true; // ✅ rack exists
      }
    }
    return false;
  }

  Future<void> updatestatus() async {
    try {
      // 🚫 BLOCK "To Print" IF RACK NOT SELECTED
      if ((selectedStatus ?? '').trim() == 'To Print' && !isRackSelected()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Rack not selected. Please select rack details first.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return; // ⛔ STOP execution
      }

      // 🔒 FREEZE STATUS UI (prevents flicker)
      setState(() {
        isUpdatingStatus = true;
      });
      final token = await getTokenFromPrefs();
      final jwt = JWT.decode(token!);
      var id = jwt.payload['id'];

      String formattedTime = DateFormat("HH:mm").format(DateTime.now());
      final isToPrint =
          (selectedStatus ?? '').trim().toLowerCase() == 'to print';

      Map<String, dynamic> body = {
        'status': selectedStatus,
        if (isToPrint && id != null) 'confirmed_by': id,
        'time': formattedTime,
        'updated_at': DateTime.now().toIso8601String().split('T')[0],
        'billing_address': selectedAddressId,
        'shipping_charge': shippingchargeController.text.trim().isNotEmpty
            ? double.parse(shippingchargeController.text)
            : 0.0,
      };

      if (accountsnoteController.text.trim().isNotEmpty) {
        body['accounts_note'] = accountsnoteController.text;
      }

      var response = await http.put(
        Uri.parse('$api/api/shipping/${widget.id}/order/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        setState(() {
          currentOrderStatus = selectedStatus;
          statusSubmitted = true;
          selectedStatus = currentOrderStatus;
        });

        await fetchOrderItems(); // ⛔ WAIT, don’t fire-and-forget

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating profile'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingStatus = false; // 🔓 UNFREEZE UI
        });
      }
    }
  }

  List<Map<String, dynamic>> _buildFlatRackDetails() {
    // _allocationsByItem: Map<int, List<Map<String, dynamic>>>
    return _allocationsByItem.values
        .expand((list) => list)
        .map((a) => {
              'rack_id': a['rack_id'],
              'rack_name': a['rack_name'],
              'column_name': a['column_name'],
              'quantity': int.tryParse('${a['quantity']}') ?? 0,
            })
        .toList();
  }

  bool _submittingAll = false;

  Future<void> submitAllAllocations() async {
    if (_submittingAll) return;

    // Prepare entries with non-empty allocations
    final entries =
        _allocationsByItem.entries.where((e) => (e.value).isNotEmpty).toList();

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No rack allocations to submit')),
      );
      return;
    }

    setState(() => _submittingAll = true);

    final successIds = <int>[];
    final failedIds = <int>[];

    // Submit SEQUENTIALLY (safe). Use Future.wait if you want parallel.
    for (final e in entries) {
      final ok = await updateOrderItem(e.key, e.value);
      if (ok) {
        successIds.add(e.key);
      } else {
        failedIds.add(e.key);
      }
    }

    // Clear only successful ones
    setState(() {
      for (final id in successIds) {
        _allocationsByItem.remove(id);
      }
      _submittingAll = false;
    });

    if (failedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submitted ${successIds.length} item(s) successfully'),
          backgroundColor: Colors.green,
        ),
      );
      // Optional: refresh items
      fetchOrderItems();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Submitted ${successIds.length} succeeded, ${failedIds.length} failed: ${failedIds.join(", ")}',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<bool> updateOrderItem(
    int itemId,
    List<Map<String, dynamic>> racks,
  ) async {
    // Clean + validate the list for JSON
    List<Map<String, dynamic>> _cleanAllocations(
        List<Map<String, dynamic>> list) {
      return list
          .map((a) => {
                'rack_id': a['rack_id'],
                'rack_name': a['rack_name'],
                'column_name': a['column_name'],
                'quantity': int.tryParse('${a['quantity']}') ?? 0,
              })
          .where((a) => (a['quantity'] as int) > 0)
          .toList();
    }

    final cleaned = _cleanAllocations(racks);
    if (cleaned.isEmpty) return true; // nothing to send for this item

    try {
      final token = await getTokenFromPrefs();
// print(cleaned);
      final body = {
        'rack_details': cleaned, // <-- flat array for THIS item only
      };

      // NOTE: adjust the path if needed. You wrote "api/api/remove...", so I assume:
      final url = Uri.parse('$api/api/remove/order/$itemId/item/');

      final res = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      // print('updateOrderItem[$itemId] => ${res.statusCode} ${res.body}');
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      // print('updateOrderItem[$itemId] error: $e');
      return false;
    }
  }

  Future<void> updateactualweight(
    var warehouseId,
    double actualWeight,
    double postOfficeAmount,
    var selectedDate,
  ) async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.put(
        Uri.parse('$api/api/warehouse/detail/$warehouseId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'actual_weight': actualWeight,
            'parcel_amount': postOfficeAmount,
            'postoffice_date': selectedDate,
          },
        ),
      );
      ;
      ;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        fetchOrderItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update '),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating '),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> updateshippeddate(DateTime pickedDate, var orderId) async {
    try {
      final token = await getTokenFromPrefs();

      var formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);

      var response = await http.put(
        Uri.parse('$api/api/warehouse/detail/$orderId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'shipped_date': formattedDate,
          },
        ),
      );
      ;
      ;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        fetchOrderItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update '),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating '),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<bool> updateparcel(var parcel, var orderId) async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.put(
        Uri.parse('$api/api/warehouse/detail/$orderId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'parcel_service': parcel,
        }),
      );

      print('updateparcel response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        await fetchOrderItems();

        if (!mounted) return true;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parcel service updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        return true;
      } else {
        if (!mounted) return false;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update parcel service'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );

        return false;
      }
    } catch (error) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating parcel service'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );

      return false;
    }
  }

  Future<void> updatetrackid(var track, var orderId) async {
    try {
      final token = await getTokenFromPrefs();
      var response = await http.put(
        Uri.parse('$api/api/warehouse/detail/$orderId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'tracking_id': track,
          },
        ),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        fetchOrderItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update e'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating '),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  List<Map<String, dynamic>> company = [];

  Future<void> getcompany() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/company/data/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // Extract the list from the response, adjust key if needed
        final List<dynamic> companyData = decoded['data'];

        List<Map<String, dynamic>> companyList = companyData.map((item) {
          return {
            'id': item['id'],
            'name': item['name'],
            // you can also include 'image': item['image'] if needed
          };
        }).toList();

        setState(() {
          company = companyList;
        });
      }
    } catch (error) {}
  }

  void showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Receipt Against Invoice Generate'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Received Date field with default today's date
                    TextField(
                      readOnly: true,
                      controller: receivedDateController,
                      decoration: InputDecoration(
                        labelText: 'Received Date',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context),
                        ),
                      ),
                    ),
                    SizedBox(height: 10), // Add spacing between fields
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(labelText: 'Amount'),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedBank,
                      items: bank
                          .map((bankItem) => DropdownMenuItem<String>(
                                value: bankItem['id'].toString(),
                                child: Text(bankItem['name']),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedBank = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Bank',
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 10.0,
                        ),
                        border: OutlineInputBorder(),
                        isDense: true, // Makes the dropdown compact
                      ),
                      isExpanded:
                          true, // Ensures the dropdown text fits properly
                    ),

                    SizedBox(height: 10),
                    TextField(
                      controller: transactionIdController,
                      decoration: InputDecoration(
                        labelText: 'Transaction ID',
                        prefixIcon: Icon(Icons.receipt),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      readOnly: true, // Make this field non-editable
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person),
                        hintText: createdBy ??
                            'Loading...', // Display the creator's name
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: remarkController,
                      decoration: InputDecoration(
                        labelText: 'Remark',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    // Handle save action here
                    AddStatusTime3(context);
                    AddReceipt(context);
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value,
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Future<String?> gettoken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString('token');
  }

  Future<void> updateaddress() async {
    if (noteController != null && selectedAddressId != null) {
      try {
        final token = await gettoken();

        var response = await http.put(
          Uri.parse('$api/api/shipping/${widget.id}/order/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(
            {
              'billing_address': selectedAddressId,
              'note': noteController.text,
            },
          ),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text('Address updated successfully'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => OrderReview(
                      id: widget.id,
                      customer: widget.customer,
                    )),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text('Failed to update Address'),
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
  }

  Future<void> updatecod() async {
    try {
      final token = await gettoken();

      var response = await http.put(
        Uri.parse('$api/api/orders/update/${widget.id}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'adv_cod_amount': advanceController.text,
            'cod_amount': codamount.text,
            'shipping_mode': shippingmethod.text,
          },
        ),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(' updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  OrderReview(id: widget.id, customer: widget.customer)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to update'),
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

  Future<void> updateorderdate(var picked) async {
    try {
      final token = await gettoken();

      var response = await http.put(
        Uri.parse('$api/api/orders/update/${widget.id}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'order_date': picked.toString(),
          },
        ),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Address updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  OrderReview(id: widget.id, customer: widget.customer)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to update Address'),
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

  Future<void> updateorderfamily() async {
    try {
      final token = await gettoken();

      var response = await http.put(
        Uri.parse('$api/api/orders/update/${widget.id}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'family': selectedfamily,
          },
        ),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Address updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  OrderReview(id: widget.id, customer: widget.customer)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to update Address'),
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

  Future<void> updateordercompany() async {
    try {
      final token = await gettoken();

      var response = await http.put(
        Uri.parse('$api/api/orders/update/${widget.id}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'company': selectedCompany,
          },
        ),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Address updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  OrderReview(id: widget.id, customer: widget.customer)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to update Address'),
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

  Future<void> updateorderpay() async {
    try {
      final token = await gettoken();

      var response = await http.put(
        Uri.parse('$api/api/orders/update/${widget.id}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'payment_status': selectedPayStatus,
          },
        ),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Address updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  OrderReview(id: widget.id, customer: widget.customer)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to update Address'),
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

  Future<void> updateorderbank() async {
    try {
      final token = await gettoken();

      var response = await http.put(
        Uri.parse('$api/api/orders/update/${widget.id}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'bank': selectedBank,
          },
        ),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Address updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  OrderReview(id: widget.id, customer: widget.customer)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to update Address'),
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

  List<Map<String, dynamic>> addres = [];

  Future<void> getaddress(var id) async {
    try {
      final token = await gettoken();

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
          String imageUrl = "${productData['image']}";
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
        });
      }
    } catch (error) {}
  }

  Future<void> getbank() async {
    final token = await gettoken();
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

  Future<void> AddReceipt(
    BuildContext scaffoldContext,
  ) async {
    final token = await gettoken();
    try {
      String formattedReceivedDate =
          DateFormat('yyyy-MM-dd').format(selectedDate);
      final response =
          await http.post(Uri.parse('$api/api/payment/${widget.id}/reciept/'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'amount': amountController.text,
                'bank': selectedBank,
                'transactionID': transactionIdController.text,
                'received_at': formattedReceivedDate,
                'created_by': createdBy,
                'remark': remarkController.text
              }));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Receipt added Successfully.'),
          ),
        );
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    OrderReview(id: widget.id, customer: widget.customer)));
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Adding receipt failed.'),
          ),
        );
      }
    } catch (e) {}
  }

  Future<void> deletebox(var orderId) async {
    try {
      final token = await getTokenFromPrefs();

      ;
      var response = await http.delete(
        Uri.parse('$api/api/warehouse/detail/$orderId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shipping charge updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update shipping charge'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      fetchOrderItems();
      fetchCustomerLedgerDetails();
    } catch (error) {
      ;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating shipping charge'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  // bool flag = false;

  Future<void> sendOrderPdfViaWhatsApp() async {
    if (ord == null) return;

    final pdf = pw.Document();

    // Styles
    final headerStyle = pw.TextStyle(
        fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.black);

    final sectionTitleStyle = pw.TextStyle(
        fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black);

    final labelStyle = pw.TextStyle(
        fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black);

    final valueStyle = pw.TextStyle(fontSize: 11, color: PdfColors.black);

    // Product Table Rows
    List<pw.TableRow> productRows = [
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text('Image', style: labelStyle),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text('Product', style: labelStyle),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text('Qty', style: labelStyle),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text('Rate', style: labelStyle),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text('Discount', style: labelStyle),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text('Tax', style: labelStyle),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text('Total', style: labelStyle),
          ),
        ],
      ),
    ];

    for (var item in items) {
      pw.Widget imageWidget = pw.Container(width: 40, height: 40);
      if (item['images'] != null && item['images'].toString().isNotEmpty) {
        try {
          final response = await http.get(Uri.parse('$api${item['images']}'));
          if (response.statusCode == 200) {
            final image = pw.MemoryImage(response.bodyBytes);
            imageWidget = pw.Container(
              width: 40,
              height: 40,
              child: pw.Image(image, fit: pw.BoxFit.cover),
            );
          }
        } catch (e) {}
      }
      productRows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: imageWidget,
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Text('${item['name'] ?? ''}', style: valueStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Text('${item['quantity'] ?? ''}', style: valueStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Text('${item['rate'] ?? ''}', style: valueStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Text('${item['discount'] ?? ''}', style: valueStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Text('${item['tax'] ?? ''}', style: valueStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Text(
                '${(((double.tryParse(item["exclude_price"].toString()) ?? 0.0) + (((double.tryParse(item["rate"].toString()) ?? 0.0) - (double.tryParse(item["discount"].toString()) ?? 0.0)) - (double.tryParse(item["exclude_price"].toString()) ?? 0.0))) * (int.tryParse(item["quantity"].toString()) ?? 1)).toStringAsFixed(2)}',
              ),
            ),
          ],
        ),
      );
    }

    // Box Details Table Rows
    List<pw.TableRow> boxRows = [
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('Image', style: labelStyle),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('Box', style: labelStyle),
          ),
          // pw.Padding(
          //   padding: pw.EdgeInsets.all(4),
          //   child: pw.Text('Packed By', style: labelStyle),
          // ),
          // pw.Padding(
          //   padding: pw.EdgeInsets.all(4),
          //   child: pw.Text('Verified By', style: labelStyle),
          // ),
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('Shipping Charge', style: labelStyle),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('Actual Weight', style: labelStyle),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('Tracking ID', style: labelStyle),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('Parcel Service', style: labelStyle),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text('Shipped Date', style: labelStyle),
          ),
        ],
      ),
    ];

    for (var box in warehouse) {
      pw.Widget boxImage = pw.Container(width: 40, height: 40);
      if (box['image'] != null && box['image'].toString().isNotEmpty) {
        try {
          final response = await http.get(Uri.parse('$api${box['image']}'));
          if (response.statusCode == 200) {
            final image = pw.MemoryImage(response.bodyBytes);
            boxImage = pw.Container(
              width: 40,
              height: 40,
              child: pw.Image(image, fit: pw.BoxFit.cover),
            );
          }
        } catch (e) {}
      }
      boxRows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.all(2),
              child: boxImage,
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(2),
              child: pw.Text('${box['box'] ?? ''}', style: valueStyle),
            ),
            // pw.Padding(
            //   padding: pw.EdgeInsets.all(2),
            //   child: pw.Text('${box['packed_by'] ?? ''}', style: valueStyle),
            // ),
            // pw.Padding(
            //   padding: pw.EdgeInsets.all(2),
            //   child: pw.Text('${box['verified_by'] ?? ''}', style: valueStyle),
            // ),
            pw.Padding(
              padding: pw.EdgeInsets.all(2),
              child:
                  pw.Text('${box['shipping_charge'] ?? ''}', style: valueStyle),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(2),
              child:
                  pw.Text('${box['actual_weight'] ?? ''}', style: valueStyle),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(2),
              child: pw.Text('${box['tracking_id'] ?? ''}', style: valueStyle),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(2),
              child:
                  pw.Text('${box['parcel_service'] ?? ''}', style: valueStyle),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(2),
              child: pw.Text('${box['shipped_date'] ?? ''}', style: valueStyle),
            ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        margin: pw.EdgeInsets.all(24),
        build: (pw.Context context) => [
          // Header
          pw.Center(
            child: pw.Text('Order Invoice', style: headerStyle),
          ),

          pw.SizedBox(height: 8),
          pw.Divider(),

          // Order Info
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Invoice No: ${ord['invoice'] ?? ''}',
                      style: labelStyle),
                  pw.Text('Order Date: ${ord["order_date"] ?? ''}',
                      style: labelStyle),
                  pw.Text('Status: ${ord["status"] ?? ''}', style: labelStyle),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Company:', style: labelStyle),
                  pw.Text('${ord['company']?['name'] ?? ''}',
                      style: valueStyle),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Billing Address
          pw.Text('Billing Address', style: sectionTitleStyle),
          pw.SizedBox(height: 4),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('${ord["billing_address"]["name"] ?? ""}',
                  style: valueStyle),
              pw.Text('${ord["billing_address"]["address"] ?? ""}',
                  style: valueStyle),
              pw.Text(
                  '${ord["billing_address"]["city"] ?? ""}, '
                  '${ord["billing_address"]["state"] ?? ""} - '
                  '${ord["billing_address"]["zipcode"] ?? ""}',
                  style: valueStyle),
              pw.Text('Phone: ${ord["billing_address"]["phone"] ?? ""}',
                  style: valueStyle),
              if (ord["billing_address"]["email"] != null)
                pw.Text('Email: ${ord["billing_address"]["email"]}',
                    style: valueStyle),
            ],
          ),

// Add vertical spacing
          pw.SizedBox(height: 16),

// Shipping Address
          pw.Text('Shipping Address', style: sectionTitleStyle),
          pw.SizedBox(height: 4),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('${ord["customer"]["name"] ?? ""}', style: valueStyle),
              pw.Text('${ord["customer"]["address"] ?? ""}', style: valueStyle),
              pw.Text(
                  '${ord["customer"]["city"] ?? ""}, ${ord["customer"]["state"] ?? ""} - ${ord["customer"]["zip_code"] ?? ""}',
                  style: valueStyle),
              pw.Text('Phone: ${ord["customer"]["phone"] ?? ""}',
                  style: valueStyle),
              if (ord["customer"]["email"] != null)
                pw.Text('Email: ${ord["customer"]["email"]}',
                    style: valueStyle),
            ],
          ),
          pw.SizedBox(height: 16),

          // Product Table
          pw.Text('Product Details', style: sectionTitleStyle),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColors.grey500,
              width: 0.5,
            ),
            children: productRows,
          ),
          pw.SizedBox(height: 16),

          // Box Details Table
          //         if (warehouse.isNotEmpty) ...[
          //           pw.Text('Box Details', style: sectionTitleStyle),
          //           pw.Table(
          //             border: pw.TableBorder.all(color: PdfColors.grey500,
          // width: 0.5,),
          //             children: boxRows,
          //           ),
          //           pw.SizedBox(height: 16),
          //         ],

          if (warehouse.isNotEmpty) ...[
            pw.Text('Tracking Details', style: sectionTitleStyle),
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 0.5,
              ),
              children: boxRows,
            ),
            pw.SizedBox(height: 16),
            // Add the clickable India Post tracking link
            pw.UrlLink(
              destination:
                  'https://www.indiapost.gov.in/_layouts/15/dop.portal.tracking/trackconsignment.aspx',
              child: pw.Text(
                'Track your consignment on India Post',
                style: pw.TextStyle(
                  color: PdfColors.grey500,
                  decoration: pw.TextDecoration.underline,
                  fontSize: 12,
                ),
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // Billing Summary
          pw.Text('Billing Summary', style: sectionTitleStyle),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey500),
              borderRadius: pw.BorderRadius.circular(6),
              color: PdfColors.grey50,
            ),
            padding: pw.EdgeInsets.all(8),
            margin: pw.EdgeInsets.only(bottom: 8, top: 4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Net Amount Before Tax:', style: labelStyle),
                    pw.Text('${netAmountBeforeTax.toStringAsFixed(2)}',
                        style: valueStyle),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Discount:', style: labelStyle),
                    pw.Text('${totalDiscount.toStringAsFixed(2)}',
                        style: valueStyle),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Tax Amount:', style: labelStyle),
                    pw.Text('${totalTaxAmount.toStringAsFixed(2)}',
                        style: valueStyle),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Payable Amount:',
                        style: labelStyle.copyWith(
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                        '${(netAmountBeforeTax + totalTaxAmount).toStringAsFixed(2)}',
                        style: valueStyle.copyWith(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green800)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Footer
          pw.Divider(),
          pw.Center(
            child: pw.Text('Thank you for your order!',
                style: pw.TextStyle(fontSize: 13, color: PdfColors.grey500)),
          ),
        ],
      ),
    );

    // Save PDF to temp directory
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/order_details.pdf');
    await file.writeAsBytes(await pdf.save());

    // Get customer phone number from billing address
    final customerPhone = ord["billing_address"]["phone"]?.toString() ?? "";
    if (customerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Customer phone number not available")),
      );
      return;
    }

    // Prepare WhatsApp message
    final message = "Order Details attached as PDF.";

    // Open share sheet with PDF attached
    await Share.shareXFiles(
      [XFile(file.path)],
      text: message,
      subject: "Order Details",
      sharePositionOrigin: Rect.fromLTWH(0, 0, 100, 100),
    );

    // Optionally, open WhatsApp chat with the customer after sharing
    // final whatsappUrl = "https://wa.me/$customerPhone?text=${Uri.encodeComponent(message)}";
    // await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
  }

  void sendWhatsAppMessage() {
    if (ord == null) return;

    final customerPhone = ord["customer"]["phone"]?.toString() ?? "";
    if (customerPhone.isEmpty) return;

    final billing = ord["billing_address"];
    final shipping = ord["customer"];

    // Build product details string
    String productDetails = "";
    for (var item in items) {
      productDetails += "\n-----------------------------\n"
          "Product: ${item['name'] ?? ''}\n"
          "Quantity: ${item['quantity'] ?? ''}\n"
          "Rate: ${item['rate'] ?? ''}\n"
          "Discount: ${item['discount'] ?? ''}\n"
          "Tax: ${item['tax'] ?? ''}\n"
          "Actual Price: ${item['actual_price'] ?? ''}\n"
          "Exclude Price: ${item['exclude_price'] ?? ''}\n";
      if (item['images'] != null && item['images'].toString().isNotEmpty) {
        productDetails += "Image: $api${item['images']}\n";
      }
    }

    // Add billing summary
    String billingSummary = "-----------------------------\n"
        "Billing Summary:\n"
        "Net Amount Before Tax: ${netAmountBeforeTax.toStringAsFixed(2)}\n"
        "Total Discount: ${totalDiscount.toStringAsFixed(2)}\n"
        "Total Tax Amount: ${totalTaxAmount.toStringAsFixed(2)}\n"
        "Total Payable Amount: ${(netAmountBeforeTax + totalTaxAmount).toStringAsFixed(2)}\n"
        "-----------------------------\n";

    final message = Uri.encodeComponent("Order Shipped!\n"
        "Billing Address:\n"
        "${billing?["name"] ?? ""}\n"
        "${billing?["address"] ?? ""}, ${billing?["city"] ?? ""}, ${billing?["state"] ?? ""}, ${billing?["zipcode"] ?? ""}\n"
        "Phone: ${billing?["phone"] ?? ""}\n"
        "Shipping Address:\n"
        "${shipping?["name"] ?? ""}\n"
        "${shipping?["address"] ?? ""}, ${shipping?["city"] ?? ""}, ${shipping?["state"] ?? ""}, ${shipping?["zip_code"] ?? ""}\n"
        "Phone: ${shipping?["phone"] ?? ""}\n"
        "Product Details:$productDetails"
        "$billingSummary"
        "Thank you for your order!");
    final whatsappUrl = "https://wa.me/$customerPhone?text=$message";
    launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
  }

  List<Map<String, dynamic>> grvList = [];

  var totalproducts;
  double totalDiscount = 0.0; // Define at the class level
  double shippingCharge = 0.0; // Define at the class level
  double actualamount = 0.0; // Define at the class level
  Future<void> fetchOrderItems() async {
    try {
      final token = await getTokenFromPrefs();

      if (token == null) {
        return;
      }
      final jwt = JWT.decode(token);
      var name = jwt.payload['name'] ?? 'Unknown'; // Provide a default value
      setState(() {
        createdBy = name;
      });
      var response = await http.get(
        Uri.parse('$api/api/order/${widget.id}/items/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("Order Items Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        List<Map<String, dynamic>> tempGrvList = [];

        for (var grv in parsed['grv'] ?? []) {
          tempGrvList.add({
            'id': grv['id'],
            'invoice': grv['invoice'],
            'product': grv['product'],
            'quantity': grv['quantity'],
            'price': grv['price'],
            'cod_amount': grv['cod_amount'],
            'remark': grv['remark'],
            'status': grv['status'],
            'date': grv['date'],
            'time': grv['time'],
            'note': grv['note'],
          });
        }

        double codReturnSum = 0.0;

        for (var grv in tempGrvList) {
          final status = grv['status']?.toString().toLowerCase();
          final remark = grv['remark']?.toString().toLowerCase();

          if (status == 'approved' && remark == 'cod_return') {
            codReturnSum += double.tryParse(
                  grv['cod_amount']?.toString() ??
                      grv['price']?.toString() ??
                      '0',
                ) ??
                0.0;
          }
        }

        ord = parsed['order'] ?? {};
        selectedserviceId = ord['parcel_service'];
        parcelServiceNoteController.text =
            ord['parcel_service_note']?.toString() ?? '';
        codamount.text = ord['cod_amount']?.toString() ?? '';
        advanceController.text = ord['adv_cod_amount']?.toString() ?? '';

        shippingmethod.text = ord['shipping_mode'] ?? '';
        noteController.text = ord['note'] ?? '';
        notebefore = ord['note'] ?? '';
        accountsnoteController.text = ord['accounts_note'] ?? '';
        shippingchargeController.text =
            ord['shipping_charge']?.toString() ?? '';
        selectedAddressId = ord['billing_address']['id'];
        List<dynamic> itemsData = parsed['items'] ?? [];
        List<dynamic> warehouseData =
            (parsed['order'] != null && parsed['order']['warehouse'] is List)
                ? parsed['order']['warehouse']
                : [];
// ❌ Do NOT override status if just submitted
        if (!statusSubmitted) {
          selectedStatus = ord['status'] ?? '';
          currentOrderStatus = ord['status'];
          beforeStatus = ord['status'] ?? '';
        }

        // selectedStatus = ord['status'] ?? '';
        selectedPayStatus = mapPayStatus(ord?["payment_status"]);
        // beforeStatus = ord['status'] ?? '';

        // currentOrderStatus = ord['status'];
        statusSubmitted = false; // reset on reload

        cod_status = ord['cod_status'] ?? '';
        advance_cod = ord['adv_cod_amount']?.toString() ?? '';
        shippingCharge = ord['shipping_charge']?.toDouble() ?? 0.0;
        actualamount = ord['total_amount']?.toDouble() ?? 0.0;
        getaddress(ord['customer']?['id']);

        List<Map<String, dynamic>> orderList = [];
        List<Map<String, dynamic>> warehouseList = [];
        double calculatedNetAmount = 0.0;
        double calculatedTotalTax = 0.0;
        var toatlquantity = 0;
        double calculatedPayableAmount = 0.0;
        double calculatedTotalDiscount = 0.0;
        // Process each item and calculate totals
        for (var item in itemsData) {
          orderList.add({
            'id': item['id'],
            'name': item['name'] ?? '',
            'rack_details': item['rack_details'] ?? [],
            'quantity': item['quantity'] ?? 0,
            'rate': item['rate'] ?? 0.0,
            'tax': item['tax'] ?? 0.0,
            'discount': item['discount'] ?? 0.0,
            'actual_price': item['actual_price'] ?? 0.0,
            'exclude_price': item['exclude_price'] ?? 0.0,
            'images': item['image'] ?? '',
            'products': item['products'] ?? '',
            'rack_details': item['rack_details'] ?? [],
          });

          double price = double.tryParse(item['rate'].toString()) ?? 0.0;
          double price_discount =
              double.tryParse(item['price_discount'].toString()) ?? 0.0;
          double excludePrice =
              double.tryParse(item['exclude_price'].toString()) ?? 0.0;
          double actualPrice =
              double.tryParse(item['actual_price'].toString()) ?? 0.0;
          double discount = double.tryParse(item['discount'].toString()) ?? 0.0;
          int quantity = int.tryParse(item['quantity'].toString()) ?? 1;

          calculatedTotalTax += (price_discount - excludePrice) * quantity;
          calculatedNetAmount += excludePrice * quantity;
          calculatedTotalDiscount += discount * quantity;
          calculatedPayableAmount += price * quantity;
          toatlquantity = toatlquantity + quantity;
        }

        // Process each warehouse item
        for (var warehouse in warehouseData) {
          warehouseList.add({
            'id': warehouse['id'],
            'box': warehouse['box'] ?? '',
            'weight': warehouse['weight'] ?? '0',
            'length': warehouse['length'] ?? '0',
            'breadth': warehouse['breadth'] ?? '0',
            'height': warehouse['height'] ?? '0',
            'image': warehouse['image'] ?? '',
            'parcel_service_id': warehouse['parcel_service_id'],
            'parcel_service_name': warehouse['parcel_service_name'] ?? '',
            'tracking_id': warehouse['tracking_id'] ?? '',
            'shipping_charge': warehouse['shipping_charge'] ?? '0.0',
            'status': warehouse['status'] ?? '',
            'shipped_date': warehouse['shipped_date'] ?? '',
            'actual_weight': warehouse['actual_weight'] ?? '0.0',
            'parcel_amount': warehouse['parcel_amount'] ?? '0.0',
            'postoffice_date': warehouse['postoffice_date'] ?? '',
            'message_status': warehouse['message_status'] ?? '',
          });
        }

        double paymentReceiptsSum = 0.0;

        for (var receipt in parsed['order']['recived_payment'] ?? []) {
          paymentReceiptsSum +=
              double.tryParse(receipt['amount'].toString()) ?? 0.0;
        }

        double remainingAmount;
        if (actualamount > paymentReceiptsSum) {
          remainingAmount = actualamount - paymentReceiptsSum;
        } else {
          remainingAmount = paymentReceiptsSum - actualamount;
        }

// 🔥 SUBTRACT APPROVED COD RETURN
        remainingAmount = remainingAmount - codReturnSum;
        if (remainingAmount < 0) remainingAmount = 0;

        setState(() {
          grvList = tempGrvList;

          items = orderList;
          totalproducts = toatlquantity;
          warehouse = warehouseList;
          netAmountBeforeTax = calculatedNetAmount;
          totalTaxAmount = calculatedTotalTax;
          payableAmount = calculatedPayableAmount;
          totalDiscount = calculatedTotalDiscount;
          Balance = remainingAmount;
          paymentreceipt = remainingAmount;
          updateamount = netAmountBeforeTax + totalTaxAmount + shippingCharge;
          approvedCodReturnAmount = codReturnSum;
        });
        // print('Order items fetched successfully$items');
// fetchCustomerLedgerDetails();
        updatingamount();
      } else {}
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching order items'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  bool isTopManagement() {
    final d = department?.toString().toUpperCase();
    return d == "CEO" || d == "COO";
  }

  bool isAdminOrAccounts() {
    return department == "ADMIN" || department == "Accounts / Accounting";
  }

  Future<void> updatingamount() async {
    try {
      final token = await getTokenFromPrefs();

      Map<String, dynamic> body = {
        'total_amount': updateamount,
      };

      var response = await http.put(
        Uri.parse('$api/api/shipping/${widget.id}/order/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Total updated successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green, // Add green background color
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red, // Add red background color
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

  Future<void> updatemsg(var orderId) async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.put(
        Uri.parse('$api/api/warehouse/detail/$orderId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'message_status': 'sent',
          },
        ),
      );

      ;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message send successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        fetchOrderItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send msg'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error in send message'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> removeproduct(int Id) async {
    final token = await getTokenFromPrefs();

    try {
      final response = await http.delete(
        Uri.parse('$api/api/remove/order/$Id/item/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color.fromARGB(255, 49, 212, 4),
            content: Text('Deleted sucessfully'),
          ),
        );
        // Navigator.push(context, MaterialPageRoute(builder: (context)=>OrderReview(id:widget.id)));
        await fetchOrderItems();
      }

      if (response.statusCode == 204) {
      } else {
        throw Exception('Failed to delete wishlist ID: $Id');
      }
    } catch (error) {}
  }

  void removeProductindex(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  List<dynamic> _decodeProducts(dynamic racksRaw) {
    if (racksRaw == null) return <dynamic>[];
    if (racksRaw is List) return racksRaw;
    if (racksRaw is String) {
      // 1) try valid JSON
      try {
        final d = jsonDecode(racksRaw);
        if (d is List) return d;
      } catch (_) {}
      // 2) fallback: convert Python-style single quotes to JSON double quotes
      try {
        final fixed = racksRaw.replaceAllMapped(
            RegExp(r"(?<!\\)'"), (m) => '"'); // unescaped ' -> "
        final d2 = jsonDecode(fixed);
        if (d2 is List) return d2;
      } catch (_) {}
    }
    return <dynamic>[];
  }

// key: itemId, value: list of allocations for that item
  final Map<int, List<Map<String, dynamic>>> _allocationsByItem = {};

  void _addAllocation(int itemId, Map<String, dynamic> chosen) {
    final list = _allocationsByItem.putIfAbsent(itemId, () => []);

    final key = '${chosen['rack_id']}|${chosen['column_name']}';
    final idx = list.indexWhere(
      (e) => '${e['rack_id']}|${e['column_name']}' == key,
    );

    if (idx >= 0) {
      // merge quantity
      final prev = int.tryParse(list[idx]['quantity'].toString()) ?? 0;
      final add = int.tryParse(chosen['quantity'].toString()) ?? 0;
      list[idx]['quantity'] = prev + add;
    } else {
      list.add({
        'rack_id': chosen['rack_id'],
        'rack_name': chosen['rack_name'],
        'column_name': chosen['column_name'],
        'quantity': chosen['quantity'],
      });
    }

    setState(() {});
  }

  Future<Map<String, dynamic>?> showPopupDialog2(
    BuildContext context,
    Map<String, dynamic> item, {
    required int remaining, // 🔹 remaining qty for this item
  }) async {
    List<dynamic> _decodeProducts(dynamic raw) {
      if (raw == null) return <dynamic>[];
      if (raw is List) return raw;
      if (raw is String) {
        try {
          final d = jsonDecode(raw);
          if (d is List) return d;
        } catch (_) {}
        try {
          final fixed = raw.replaceAllMapped(RegExp(r"(?<!\\)'"), (m) => '"');
          final d2 = jsonDecode(fixed);
          if (d2 is List) return d2;
        } catch (_) {}
      }
      return <dynamic>[];
    }

    final racks = _decodeProducts(item['products']);

    int _asInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;
    int _available(Map r) => _asInt(r['rack_stock']) - _asInt(r['rack_lock']);

    final usableRacks = racks
        .where((r) {
          if (r is! Map) return false;
          final u = r['usability']?.toString().trim().toLowerCase();
          return u == 'usable';
        })
        .cast<Map<String, dynamic>>()
        .toList();

    String? selectedKey;
    Map<String, dynamic>? selectedRack;
    String qtyText = '';
    String? errorText;

    bool canConfirm() {
      if (selectedRack == null) return false;
      final q = int.tryParse(qtyText);
      if (q == null || q <= 0) return false;
      final rackAvail = _available(selectedRack!);
      final cap = rackAvail < remaining ? rackAvail : remaining;
      return q <= cap;
    }

    void validate() {
      final q = int.tryParse(qtyText);
      if (selectedRack == null) {
        errorText = null;
        return;
      }
      final rackAvail = _available(selectedRack!);
      if (q == null || q < 0) {
        errorText = 'Enter a quantity greater than 0';
      } else if (q > rackAvail) {
        errorText = 'Exceeds rack availability ($rackAvail)';
      } else if (q > remaining) {
        errorText = 'Exceeds remaining item quantity ($remaining)';
      } else {
        errorText = null;
      }
    }

    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final insets = MediaQuery.of(sheetCtx).viewInsets;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + insets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((item['name'] ?? 'Product').toString(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (usableRacks.isEmpty)
                    const Text('No usable rack slots for this product.',
                        style: TextStyle(color: Colors.grey))
                  else
                    DropdownButtonFormField<String>(
                      isExpanded:
                          true, // 👈 lets the button use all horizontal space
                      decoration: const InputDecoration(
                        labelText: 'Select rack slot',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      value: selectedKey,
                      items: usableRacks.map<DropdownMenuItem<String>>((r) {
                        final key = '${r['rack_id']}|${r['column_name']}';
                        final label =
                            '${r['rack_name'] ?? ''} - ${r['column_name'] ?? ''} '
                            '(stock: ${r['rack_stock'] ?? 0}, lock: ${r['rack_lock'] ?? 0}, '
                            'avail: ${_available(r)})';

                        // 👇 Ellipsize the *menu* items
                        return DropdownMenuItem(
                          value: key,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      // 👇 Ellipsize the *selected* item (the closed state)
                      selectedItemBuilder: (_) {
                        return usableRacks.map<Widget>((r) {
                          final label =
                              '${r['rack_name'] ?? ''} - ${r['column_name'] ?? ''} '
                              '(stock: ${r['rack_stock'] ?? 0}, lock: ${r['rack_lock'] ?? 0}, '
                              'avail: ${_available(r)})';
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          );
                        }).toList();
                      },

                      onChanged: (val) {
                        setSheetState(() {
                          selectedKey = val;
                          selectedRack = (val == null)
                              ? null
                              : usableRacks.firstWhere(
                                  (r) =>
                                      '${r['rack_id']}|${r['column_name']}' ==
                                      val,
                                );
                          validate();
                        });
                      },
                    ),
                  const SizedBox(height: 12),
                  if (selectedRack != null) ...[
                    TextFormField(
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        helperText:
                            'Rack avail: ${_available(selectedRack!)}, Remaining item: $remaining',
                        errorText: errorText,
                      ),
                      onChanged: (val) {
                        setSheetState(() {
                          qtyText = val.trim();
                          validate();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: canConfirm()
                              ? () {
                                  final chosen = <String, dynamic>{
                                    'rack_id': selectedRack!['rack_id'],
                                    'rack_name': selectedRack!['rack_name'],
                                    'column_name': selectedRack!['column_name'],
                                    'quantity': int.parse(qtyText),
                                  };
                                  Navigator.pop(sheetCtx, chosen);
                                }
                              : null,
                          child: const Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showPopupDialog(BuildContext context, Map<String, dynamic> item) {
    TextEditingController quantityController =
        TextEditingController(text: item['quantity']?.toString() ?? '');
    TextEditingController discountController =
        TextEditingController(text: item['discount']?.toString() ?? '');
    TextEditingController priceController =
        TextEditingController(text: item['rate']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Edit Item Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: discountController,
                decoration: InputDecoration(
                    labelText: 'Discount (in Rs for each product)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final quantity =
                    int.tryParse(quantityController.text) ?? item['quantity'];
                final discount = double.tryParse(discountController.text) ??
                    item['discount'];

                final upprice =
                    double.tryParse(priceController.text) ?? item['rate'];

                updatedetails(item['id'], quantity, discount, upprice);
                Navigator.of(context).pop();
                fetchOrderItems();
                fetchCustomerLedgerDetails();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updatedetails(
      int id, int quantity, double discount, var price) async {
    try {
      final token = await getTokenFromPrefs();
      final response = await http.put(
        Uri.parse('$api/api/remove/order/$id/item/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
            {'quantity': quantity, 'discount': discount, 'rate': price}),
      );
// print(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cart item updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await fetchOrderItems();
        // Navigator.push(context, MaterialPageRoute(builder: (context)=>OrderReview(id: widget.id)));
      } else {
        throw Exception('Failed to update cart item');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update cart item'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDatePicker(BuildContext context, int orderId) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      updateshippeddate(picked, orderId);
    }
  }

  void _showDatePicker2(BuildContext context, int orderId) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      updateorderdate(picked);
    }
  }

  List<Map<String, dynamic>> customer = [];
  Future<void> getcustomer({
    int page = 1,
    String search = "",
    Function? refreshModal,
  }) async {
    try {
      final token = await getTokenFromPrefs();

      String url = "$api/api/customers/?page=$page&search=$search";

      var response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List results = parsed['results'];

        int count = parsed['count'];
        totalPages = (count / 10).ceil();

        List<Map<String, dynamic>> newCustomers = [];

        for (var c in results) {
          newCustomers.add({
            'id': c['id'],
            'name': c['name'],
          });
        }

        if (refreshModal != null) {
          refreshModal(() {
            customer = newCustomers;
            filteredCustomers = newCustomers;
            currentPage = page;
            customersLoaded = true;
          });
        } else {
          setState(() {
            customer = newCustomers;
            filteredCustomers = newCustomers;
            currentPage = page;
            customersLoaded = true;
          });
        }
      } else {
        if (refreshModal != null) {
          refreshModal(() {
            customersLoaded = false;
          });
        } else {
          setState(() {
            customersLoaded = false;
          });
        }
      }
    } catch (e) {
      print("Customer fetch error: $e");
      if (refreshModal != null) {
        refreshModal(() {
          customersLoaded = false;
        });
      } else {
        setState(() {
          customersLoaded = false;
        });
      }
    }
  }

  Future<void> updatecustomer() async {
    try {
      final token = await getTokenFromPrefs();

      final jwt = JWT.decode(token!);
      var id = jwt.payload['id']; // Expected to be an int
      String formattedTime = DateFormat("HH:mm").format(DateTime.now());
      final isToPrint =
          (selectedStatus ?? '').toString().trim().toLowerCase() == 'to print';
      Map<String, dynamic> body = {
        'customer': selectedCustomer?['id'],
      };
      var response = await http.put(
        Uri.parse('$api/api/shipping/${widget.id}/order/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      // print("body==================${body}");

      if (response.statusCode == 200) {
        fetchOrderItems();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('status updated successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green, // Add green background color
          ),
        );
        //  Navigator.pushReplacement(
        //       context,
        //       MaterialPageRoute(builder: (context) => OrderList(status:null)),
        //     );
        fetchOrderItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red, // Add red background color
          ),
        );
      }
    } catch (error) {
      // print("error==================${error}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _openCustomerSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (customer.isEmpty) {
              getcustomer(page: 1, refreshModal: setModalState);
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.50,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person_search,
                                color: Colors.blue,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Select Customer',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search by customer name',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 1.4,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            searchQuery = value;
                            getcustomer(
                              page: 1,
                              search: value,
                              refreshModal: setModalState,
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: currentPage > 1
                                      ? () {
                                          getcustomer(
                                            page: currentPage - 1,
                                            search: searchQuery,
                                            refreshModal: setModalState,
                                          );
                                        }
                                      : null,
                                  icon:
                                      const Icon(Icons.chevron_left, size: 18),
                                  label: const Text("Prev"),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        Colors.grey.shade300,
                                    disabledForegroundColor:
                                        Colors.grey.shade600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  "Page $currentPage / $totalPages",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: currentPage < totalPages
                                      ? () {
                                          getcustomer(
                                            page: currentPage + 1,
                                            search: searchQuery,
                                            refreshModal: setModalState,
                                          );
                                        }
                                      : null,
                                  icon:
                                      const Icon(Icons.chevron_right, size: 18),
                                  label: const Text("Next"),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        Colors.grey.shade300,
                                    disabledForegroundColor:
                                        Colors.grey.shade600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: customer.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 46,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        "No customers found",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  itemCount: customer.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final c = customer[index];
                                    final bool isSelected =
                                        selectedCustomer?['id'] == c['id'];

                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () async {
                                          final confirmed =
                                              await _showCustomerConfirmPopup(
                                                  context, c);

                                          if (confirmed == true) {
                                            setState(() {
                                              selectedCustomer = c;
                                            });

                                            await updatecustomer();
                                            Navigator.pop(context);
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 14,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.blue.shade50
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.blue
                                                  : Colors.grey.shade300,
                                              width: isSelected ? 1.3 : 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.04),
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 42,
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.person,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      c['name'] ?? '',
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "Tap to update billing customer",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                isSelected
                                                    ? Icons.check_circle
                                                    : Icons.arrow_forward_ios,
                                                size: isSelected ? 22 : 16,
                                                color: isSelected
                                                    ? Colors.blue
                                                    : Colors.grey.shade500,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
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
      },
    );
  }

  Future<bool?> _showCustomerConfirmPopup(
      BuildContext context, Map<String, dynamic> customer) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: const [
              Icon(Icons.verified_user, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Confirm Update',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
              children: [
                const TextSpan(text: 'Change billing customer to\n\n'),
                TextSpan(
                  text: customer['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' ?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _confirmCustomerUpdate(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Update'),
          content: Text(
            'Are you sure you want to change the customer to '
            '${tempSelectedCustomer?['name']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Widget _simpleEditIcon(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(
          Icons.edit,
          size: 16,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _orderInfoLabel(String text) {
    return SizedBox(
      width: 120,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String status = ord?['status']?.toString().toLowerCase() ?? '';

    final String dept = (dep ?? '').toString().toLowerCase();
   final bool canShowParcelTopSection =
    ord != null &&
    (
      (dept == "bdo" && ord["status"] == "Invoice Created") ||
      (dept != "bdo" &&
          (ord["status"] == "Invoice Created" ||
              ord["status"] == "Invoice Approved"))
    );

    final bool showAddProductButton =
        dept != 'bdo' || (dept == 'bdo' && status == 'invoice created');

    final visibleItems = showAllProducts ? items : items.take(3).toList();
    return WillPopScope(
      onWillPop: () async {
        // Trigger the navigation logic when the back swipe occurs
        Navigator.pop(context);
        return false; // Prevent the default back navigation behavior
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                height: 160,
                child: Column(
                  children: [
                    SizedBox(height: 50),
                    Row(
                      children: [
                        SizedBox(width: 13),
                        Container(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 220, 220, 220),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.local_shipping,
                              size: 40, color: Colors.blue),
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ord != null
                                      ? ord['invoice'] ?? 'Invoice Number'
                                      : 'Loading...',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final Uri url =
                                        Uri.parse('$api/invoice/${ord['id']}/');

                                    if (!await launchUrl(url,
                                        mode: LaunchMode.externalApplication)) {
                                      // Handle error case
                                    }
                                  },
                                  icon: Icon(
                                    Icons.download,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    SizedBox(
                      height: 5,
                    )
                  ],
                ),
              ),
              grvCard(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  color: Colors.white,
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15.0),
                            topRight: Radius.circular(15.0),
                          ),
                        ),
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ord != null
                                  ? ord['manage_staff'] ?? 'manage_staff'
                                  : 'Loading...',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            if (dep != "BDO")
                              GestureDetector(
                                onTap: () {
                                  _showDatePicker2(context, ord['id']);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4), // Add padding
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 2, 88,
                                        158), // Set the background color
                                    borderRadius: BorderRadius.circular(
                                        8), // Optional: Add rounded corners
                                  ),
                                  child: Text(
                                    ord != null && ord["order_date"] != null
                                        ? DateFormat('yyyy-MM-dd').format(
                                            DateTime.parse(ord["order_date"])
                                                .toLocal())
                                        : 'Date Not Available',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: .0),
                            Row(
                              children: [
                                Text(
                                  'Status: ',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                Spacer(),
                                Text(
                                  ord != null
                                      ? '${ord["status"]}'
                                      : 'Loading...',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.0),
                            if (dep != "BDM" && dep != "BDO")
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _orderInfoLabel('Payment Method'),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: showPayStatusDropdown
                                        ? DropdownButtonFormField<String>(
                                            value: selectedPayStatus,
                                            isExpanded: true,
                                            items: paystatus.map((status) {
                                              return DropdownMenuItem<String>(
                                                value: status,
                                                child: Text(status,
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                selectedPayStatus = newValue;
                                                showPayStatusDropdown = false;
                                              });
                                              updateorderpay();
                                            },
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 8),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black),
                                          )
                                        : Text(
                                            ord != null
                                                ? '${ord["payment_status"]}'
                                                : 'Loading...',
                                            textAlign: TextAlign.right,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                  ),
                                  _simpleEditIcon(() {
                                    setState(() {
                                      showPayStatusDropdown =
                                          !showPayStatusDropdown;
                                      showCodTypeDropdown = false;
                                      showFamilyDropdown = false;
                                      showCompanyDropdown = false;
                                      showParcelServiceDropdown = false;
                                      showParcelNoteField = false;
                                    });
                                  }),
                                ],
                              ),

                            const SizedBox(height: 4),

                            if (dep != "BDM" && dep != "BDO")
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _orderInfoLabel('COD Type'),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: showCodTypeDropdown
                                        ? DropdownButtonFormField<String>(
                                            value: cod_status == ""
                                                ? null
                                                : cod_status,
                                            isExpanded: true,
                                            items: codtype.map((status) {
                                              return DropdownMenuItem<String>(
                                                value: status,
                                                child: Text(status,
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                cod_status = newValue;
                                                showCodTypeDropdown = false;
                                              });
                                              updateordercodtype();
                                            },
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 8),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black),
                                          )
                                        : Text(
                                            ord != null
                                                ? '${ord["cod_status"]}'
                                                : 'Loading...',
                                            textAlign: TextAlign.right,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                  ),
                                  _simpleEditIcon(() {
                                    setState(() {
                                      showCodTypeDropdown =
                                          !showCodTypeDropdown;
                                      showPayStatusDropdown = false;
                                      showFamilyDropdown = false;
                                      showCompanyDropdown = false;
                                      showParcelServiceDropdown = false;
                                      showParcelNoteField = false;
                                    });
                                  }),
                                ],
                              ),

                            const SizedBox(height: 4),

                            if (dep != "BDM" && dep != "BDO")
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _orderInfoLabel('Division'),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: showFamilyDropdown
                                        ? DropdownButtonFormField<String>(
                                            value: selectedfamily ??
                                                (ord != null
                                                    ? ord["family_id"]
                                                        ?.toString()
                                                    : null),
                                            isExpanded: true,
                                            hint: Text(
                                              ord != null
                                                  ? ord["family"] ??
                                                      "Select Division"
                                                  : "Select Division",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            items: fam
                                                .map<DropdownMenuItem<String>>(
                                                    (item) {
                                              return DropdownMenuItem<String>(
                                                value: item['id'].toString(),
                                                child: Text(item['name'],
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                selectedfamily = newValue;
                                                showFamilyDropdown = false;
                                              });
                                              updateorderfamily();
                                            },
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 8),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black),
                                          )
                                        : Text(
                                            ord != null
                                                ? ord["family"] ?? 'None'
                                                : 'Loading...',
                                            textAlign: TextAlign.right,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                  ),
                                  _simpleEditIcon(() {
                                    setState(() {
                                      showFamilyDropdown = !showFamilyDropdown;
                                      showPayStatusDropdown = false;
                                      showCodTypeDropdown = false;
                                      showCompanyDropdown = false;
                                      showParcelServiceDropdown = false;
                                      showParcelNoteField = false;
                                    });
                                  }),
                                ],
                              ),

                            const SizedBox(height: 4),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _orderInfoLabel('Company'),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: showCompanyDropdown
                                      ? DropdownButtonFormField<String>(
                                          value: selectedCompany ??
                                              (ord != null
                                                  ? ord['company']['id']
                                                      .toString()
                                                  : null),
                                          isExpanded: true,
                                          hint: Text(
                                            ord != null
                                                ? ord['company']['name'] ??
                                                    'Select Company'
                                                : 'Select Company',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          items: company
                                              .map<DropdownMenuItem<String>>(
                                                  (companyItem) {
                                            return DropdownMenuItem<String>(
                                              value:
                                                  companyItem['id'].toString(),
                                              child: Text(
                                                companyItem['name'],
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              selectedCompany = newValue;
                                              showCompanyDropdown = false;
                                            });
                                            updateordercompany();
                                          },
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 8),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black),
                                        )
                                      : Text(
                                          ord != null
                                              ? ord['company']['name'] ??
                                                  'Select Company'
                                              : 'Loading...',
                                          textAlign: TextAlign.right,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                ),
                                _simpleEditIcon(() {
                                  setState(() {
                                    showCompanyDropdown = !showCompanyDropdown;
                                  });
                                }),
                              ],
                            ),

                            SizedBox(height: 4.0),

                            

                            if (canShowParcelTopSection)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _orderInfoLabel('Parcel Service'),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: showParcelServiceDropdown
                                        ? DropdownButtonFormField<int>(
                                            value: courierdata.any(
                                              (e) =>
                                                  e['id'].toString() ==
                                                  selectedserviceId?.toString(),
                                            )
                                                ? int.tryParse(selectedserviceId
                                                    .toString())
                                                : null,
                                            isExpanded: true,
                                            hint: const Text(
                                              'Select Service',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            items: courierdata
                                                .map<DropdownMenuItem<int>>(
                                                    (item) {
                                              return DropdownMenuItem<int>(
                                                value: int.tryParse(
                                                    item['id'].toString()),
                                                child: Text(
                                                  item['name']?.toString() ??
                                                      '',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (int? newValue) {
                                              setState(() {
                                                selectedserviceId = newValue;
                                                showParcelServiceDropdown =
                                                    false;
                                              });
                                              updateOrderParcelDetails();
                                            },
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 8),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black),
                                          )
                                        : Text(
                                            ord != null
                                                ? getCourierName(
                                                    ord['parcel_service'])
                                                : 'Loading...',
                                            textAlign: TextAlign.right,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                  ),
                                  _simpleEditIcon(() {
                                    setState(() {
                                      showParcelServiceDropdown =
                                          !showParcelServiceDropdown;
                                      showParcelNoteField = false;
                                      showPayStatusDropdown = false;
                                      showCodTypeDropdown = false;
                                      showFamilyDropdown = false;
                                      showCompanyDropdown = false;
                                    });
                                  }),
                                ],
                              ),

                            if (canShowParcelTopSection)
                              const SizedBox(height: 4),

                            if (canShowParcelTopSection)
                              Row(
                                crossAxisAlignment: showParcelNoteField
                                    ? CrossAxisAlignment.start
                                    : CrossAxisAlignment.center,
                                children: [
                                  _orderInfoLabel('Parcel Note'),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: showParcelNoteField
                                        ? TextField(
                                            controller:
                                                parcelServiceNoteController,
                                            minLines: 1,
                                            maxLines: 2,
                                            style:
                                                const TextStyle(fontSize: 12),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              hintText: 'Enter parcel note',
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 8),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onSubmitted: (_) {
                                              setState(() {
                                                showParcelNoteField = false;
                                              });
                                              updateOrderParcelDetails();
                                            },
                                          )
                                        : Text(
                                            parcelServiceNoteController.text
                                                    .trim()
                                                    .isNotEmpty
                                                ? parcelServiceNoteController
                                                    .text
                                                    .trim()
                                                : 'No note',
                                            textAlign: TextAlign.right,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                  ),
                                  showParcelNoteField
                                      ? IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                          icon: const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              showParcelNoteField = false;
                                            });
                                            updateOrderParcelDetails();
                                          },
                                        )
                                      : _simpleEditIcon(() {
                                          setState(() {
                                            showParcelNoteField = true;
                                            showParcelServiceDropdown = false;
                                            showPayStatusDropdown = false;
                                            showCodTypeDropdown = false;
                                            showFamilyDropdown = false;
                                            showCompanyDropdown = false;
                                          });
                                        }),
                                ],
                              ),

                            if (ord != null && ord["status"] == "Shipped")
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors
                                              .white, // Text & icon color (for latest Flutter)
                                        ),
                                        icon: Icon(Icons.message,
                                            size: 18, color: Colors.white),
                                        label: Text("Send Text"),
                                        onPressed: sendWhatsAppMessage,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        icon: Icon(Icons.picture_as_pdf,
                                            size: 18, color: Colors.white),
                                        label: Text("Send PDF"),
                                        onPressed: sendOrderPdfViaWhatsApp,
                                      ),
                                    ),
                                  ],
                                ),
                              )

                            // if (ord != null && ord['shipping_mode'] != null)
                            //   Row(
                            //     children: [
                            //       Text(
                            //         'Shipping Mode',
                            //         style: TextStyle(
                            //             fontSize: 12,
                            //             fontWeight: FontWeight.w600),
                            //       ),
                            //       Spacer(),
                            //       Text(
                            //         '${ord['shipping_mode']}',
                            //         style: TextStyle(
                            //             color: const Color.fromARGB(255, 0, 0, 0),
                            //             fontSize: 12),
                            //       ),
                            //     ],
                            //   ),
                            // if (ord != null &&
                            //     ord['cod_amount'] != null &&
                            //     ord['cod_amount'] != 0)
                            //   SizedBox(height: 4.0),
                            // if (ord != null &&
                            //     ord['cod_amount'] != null &&
                            //     ord['cod_amount'] != 0)
                            //   Row(
                            //     children: [
                            //       Text(
                            //         'Code Charge',
                            //         style: TextStyle(
                            //             fontSize: 12,
                            //             fontWeight: FontWeight.w600),
                            //       ),
                            //       Spacer(),
                            //       Text(
                            //         ' ${ord['cod_amount']}',
                            //         style: TextStyle(
                            //             color: const Color.fromARGB(255, 0, 0, 0),
                            //             fontSize: 12),
                            //       ),
                            //     ],
                            //   ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 5,
              ),
              if (dep != "BDM" && dep != "BDO")
                Padding(
                  padding: const EdgeInsets.only(right: 10, left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: shippingmethod,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      20.0), // Add border radius
                                ),
                                labelText: 'Shipping Mode',
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: codamount,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      20.0), // Add border radius
                                ),
                                labelText: 'COD Amount',
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: advanceController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      20.0), // Add border radius
                                ),
                                labelText: 'Advance COD Amount',
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                updatecod();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.blue, // Set background color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      12.0), // Add border radius
                                ),
                              ),
                              child: Text('Save Changes',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 15, left: 15),
                child: Divider(),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedCustomer != null
                              ? 'Billing Address - ${selectedCustomer!['name']}'
                              : 'Billing Address',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (dep != "BDM" && dep != "BDO")
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () async {
                              await getcustomer(page: 1, search: "");
                              _openCustomerSelector(context);
                            },
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      ord != null ? '${ord["customer"]["name"]}' : 'Loading...',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      ord != null
                          ? '${ord["customer"]["address"]}, ${ord["customer"]["city"]}, ${ord["customer"]["state"]}, ${ord["customer"]["zip_code"]}'
                          : 'Loading...',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      ord != null
                          ? 'Phone: ${ord["customer"]["phone"]}'
                          : 'Loading...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      ord != null
                          ? 'Email: ${ord["customer"]["email"]}'
                          : 'Loading...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      ord != null
                          ? 'GST: ${ord["customer"]["gst"]}'
                          : 'Loading...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      ord != null
                          ? 'GST Confirmation: ${ord["customer"]["gst_confirm"]}'
                          : 'Loading...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 15, left: 15),
                child: Divider(),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shipping Address',
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      ord != null && ord["billing_address"] != null
                          ? '${ord["billing_address"]["name"]}'
                          : 'N/A',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      ord != null
                          ? '${ord["billing_address"]["address"]}, ${ord["billing_address"]["city"]}, ${ord["billing_address"]["state"]}, ${ord["billing_address"]["zipcode"]}'
                          : 'Loading...',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      ord != null
                          ? 'Phone: ${ord["billing_address"]["phone"]}'
                          : 'Loading...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      ord != null
                          ? 'Email: ${ord["billing_address"]["email"]}'
                          : 'Loading...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 15, left: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Products view',
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),

                    // Display each item in the visibleItems list within a card
                    for (var item in visibleItems)
                      GestureDetector(
                        onTap: () {
                          showPopupDialog(context, item);
                        },
                        child: Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Display the first image in a small container
                                Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image:
                                          NetworkImage('$api${item["images"]}'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                // Display product details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'],
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Quantity: ${item["quantity"]}, Rate: ${item["rate"]}',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            'discount: ${item["discount"]}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                          SizedBox(
                                            width: 4,
                                          ),
                                          if (item["tax"] != 0)
                                            Text(
                                              'Tax: ${item["tax"]}',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            )
                                        ],
                                      ),
                                      Text(
                                        'Rate After Discount: ₹${item["rate"] ?? 0.0 - item["discount"] ?? 0.0}',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),

                                      Text(
                                        'Total: ₹${(((double.tryParse(item["exclude_price"].toString()) ?? 0.0) + (((double.tryParse(item["rate"].toString()) ?? 0.0) - (double.tryParse(item["discount"].toString()) ?? 0.0)) - (double.tryParse(item["exclude_price"].toString()) ?? 0.0))) * (int.tryParse(item["quantity"].toString()) ?? 1)).toStringAsFixed(2)}',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      // ...existing code...
                                      Text(
                                        'Excluded price: ${item["exclude_price"]}',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      // ...existing code...
                                      Row(
                                        children: [
                                          Text(
                                            'Total: ${(((double.tryParse(item["exclude_price"].toString()) ?? 0.0) + (((double.tryParse(item["rate"].toString()) ?? 0.0) - (double.tryParse(item["discount"].toString()) ?? 0.0)) - (double.tryParse(item["exclude_price"].toString()) ?? 0.0))) * (int.tryParse(item["quantity"].toString()) ?? 1)).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const Spacer(),

                                          // 🔹 New button to show rack details
                                          if (dep != "BDM" && dep != "BDO")
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.inventory_2,
                                                  color: Colors.blue,
                                                  size: 22),
                                              tooltip: 'View Rack Details',
                                              onPressed: () async {
                                                final itemId = int.tryParse(
                                                        item['id']
                                                            .toString()) ??
                                                    0;
                                                final ordered = int.tryParse(
                                                        item['quantity']
                                                            .toString()) ??
                                                    0;
                                                final already = (_allocationsByItem[
                                                            itemId] ??
                                                        [])
                                                    .fold<int>(
                                                        0,
                                                        (s, a) =>
                                                            s +
                                                            (int.tryParse(
                                                                    '${a['quantity']}') ??
                                                                0));
                                                final remaining =
                                                    (ordered - already);

                                                if (remaining <= 0) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            'Allocation complete for this product.')),
                                                  );
                                                  return;
                                                }

                                                final result =
                                                    await showPopupDialog2(
                                                        context, item,
                                                        remaining: remaining);
                                                if (result != null) {
                                                  // Final guard after return (defensive)
                                                  final addQty = int.tryParse(
                                                          '${result['quantity']}') ??
                                                      0;
                                                  if (already + addQty >
                                                      ordered) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'Exceeds total item quantity ($ordered).')),
                                                    );
                                                    return;
                                                  }
                                                  _addAllocation(
                                                      itemId, result);
                                                }
                                              },
                                            ),

                                          if (dep != "BDM" && dep != "BDO")
                                            GestureDetector(
                                              onTap: () {
                                                removeproduct(item["id"]);
                                                fetchOrderItems();
                                              },
                                              child: Image.asset(
                                                  height: 25,
                                                  width: 25,
                                                  "lib/assets/delete.png"),
                                            )
                                        ],
                                      ),

                                      Builder(
                                        builder: (_) {
                                          final itemId = int.tryParse(
                                                  item['id'].toString()) ??
                                              0;

                                          // Pending allocations you built locally (per item)
                                          final List<Map<String, dynamic>>
                                              localAllocs =
                                              (_allocationsByItem[itemId] ?? [])
                                                  .cast<Map<String, dynamic>>();

                                          // Existing allocations from API response: item['rack_details']
                                          final List<Map<String, dynamic>>
                                              serverAllocs =
                                              (item['rack_details'] is List)
                                                  ? (item['rack_details']
                                                          as List)
                                                      .whereType<
                                                          Map>() // keep only maps
                                                      .map<
                                                          Map<String,
                                                              dynamic>>((m) => {
                                                            'rack_id':
                                                                m['rack_id'],
                                                            'rack_name':
                                                                m['rack_name'],
                                                            'column_name': m[
                                                                'column_name'],
                                                            'quantity':
                                                                m['quantity'],
                                                          })
                                                      .toList()
                                                  : <Map<String, dynamic>>[];

                                          final hasAny =
                                              serverAllocs.isNotEmpty ||
                                                  localAllocs.isNotEmpty;
                                          if (!hasAny)
                                            return const SizedBox.shrink();

                                          Widget chipsFor(
                                              List<Map<String, dynamic>> list,
                                              {required bool deletable}) {
                                            return Wrap(
                                              spacing: 8,
                                              runSpacing: 6,
                                              children: list.map((a) {
                                                final rack = (a['rack_name'] ??
                                                        a['rack_id'] ??
                                                        '')
                                                    .toString();
                                                final col =
                                                    (a['column_name'] ?? '')
                                                        .toString();
                                                final qty = int.tryParse(
                                                        '${a['quantity']}') ??
                                                    0;
                                                final label =
                                                    '$rack${col.isNotEmpty ? '-$col' : ''} x $qty';

                                                return Chip(
                                                  label: Text(label,
                                                      style: const TextStyle(
                                                          fontSize: 12)),
                                                  // grey style for existing/server chips
                                                  backgroundColor: deletable
                                                      ? null
                                                      : const Color(0xFFE9ECEF),
                                                  deleteIcon: deletable
                                                      ? const Icon(Icons.close,
                                                          size: 16)
                                                      : null,
                                                  onDeleted: deletable
                                                      ? () {
                                                          setState(() {
                                                            localAllocs
                                                                .remove(a);
                                                            if (localAllocs
                                                                .isEmpty) {
                                                              _allocationsByItem
                                                                  .remove(
                                                                      itemId);
                                                            }
                                                          });
                                                        }
                                                      : null,
                                                );
                                              }).toList(),
                                            );
                                          }

                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (serverAllocs.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                const Text(
                                                    'Existing allocation',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                chipsFor(serverAllocs,
                                                    deletable: false),
                                              ],
                                              if (localAllocs.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                const Text('New allocation',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                chipsFor(localAllocs,
                                                    deletable: true),
                                              ],
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // "See More" or "See Less" Button
                    if (items.length >
                        3) // Show button only if there are more than 3 items
                      TextButton(
                        onPressed: () {
                          setState(() {
                            showAllProducts =
                                !showAllProducts; // Toggle the visibility
                          });
                        },
                        child: Text(
                          showAllProducts ? 'See Less' : 'See More',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                  ],
                ),
              ),
              if (dep != "BDM" && dep != "BDO")
                Center(
                  child: ElevatedButton(
                    onPressed: _submittingAll
                        ? null
                        : () async {
                            await submitAllAllocations();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 3, 125, 247),
                    ),
                    child: Text(
                      _submittingAll ? 'Submitting...' : 'Submit Rack Details',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Screenshots',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 8),

                        // 🔥 SHOW NEWLY SELECTED IMAGES FIRST
                        if (selectedImageslist.isNotEmpty)
                          Text("Selected Images"),
                        if (selectedImageslist.isNotEmpty)
                          SizedBox(
                            height: 70,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: selectedImageslist.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          selectedImageslist[index],
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedImageslist.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          child: Icon(Icons.close,
                                              color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                        SizedBox(height: 12),

                        // 🔥 SHOW SERVER IMAGES AFTER SELECTED IMAGES
                        if (selectedImageData.isNotEmpty)
                          Text("Uploaded Images"),
                        if (selectedImageData.isNotEmpty)
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: selectedImageData.length,
                              itemBuilder: (context, index) {
                                final imageItem = selectedImageData[index];

                                return Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => Dialog(
                                            backgroundColor: Colors.transparent,
                                            child: InteractiveViewer(
                                              child: Image.network(
                                                  imageItem['imageUrl']),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4.0),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            imageItem['imageUrl'],
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () {
                                          deleteimage(imageItem['id']);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          child: Icon(Icons.close,
                                              color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: selectMultipleImages,
                              icon:
                                  Icon(Icons.add_a_photo, color: Colors.black),
                              label: Text("Add Images",
                                  style: TextStyle(color: Colors.black)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                addimages(context);
                              },
                              child: Text("Submit Images",
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )),
              ),
              SizedBox(height: 10),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50], // Light red background
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.production_quantity_limits,
                        color: Colors.red, size: 28),
                    SizedBox(width: 7),
                    Text(
                      "Total Products: ${totalproducts}",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[800],
                      ),
                    ),
                  ],
                ),
              ),
              if (showAddProductButton)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color.fromARGB(255, 10, 186, 1),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => update_order_products(
                              id: widget.id,
                              customer: widget.customer,
                            ),
                          ),
                        );
                      },
                      child: const Text("Add Product"),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 2, 65, 96),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 3,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Bank Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Spacer(),
                          Image.asset(
                              height: 40, width: 40, 'lib/assets/money.png'),
                          Icon(
                            Icons.credit_card,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
                      // Row(
                      //   children: [

                      //     Image.asset(
                      //         height: 40, width: 40, 'lib/assets/money.png')
                      //   ],
                      // ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              showBankDropdown = !showBankDropdown;
                            });
                          },
                          child: showBankDropdown
                              ? Container(
                                  width: 200,
                                  child: DropdownButtonFormField<String>(
                                    value: selectedBank ??
                                        (ord != null
                                            ? ord["bank"]["id"].toString()
                                            : null),
                                    items: bank.map((bankItem) {
                                      return DropdownMenuItem<String>(
                                        value: bankItem['id'].toString(),
                                        child: Text(bankItem['name']),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedBank = newValue;
                                        showBankDropdown = false;
                                      });
                                      updateorderbank();
                                    },
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                )
                              : Text(
                                  ord != null
                                      ? ord["bank"]["name"]
                                      : 'Loading...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    letterSpacing: 2,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Column(
                          //   crossAxisAlignment: CrossAxisAlignment.start,
                          //   children: [
                          //     Text(
                          //       'Account Holder',
                          //       style: TextStyle(
                          //         color: Colors.grey[400],
                          //         fontSize: 12,
                          //       ),
                          //     ),
                          //     Text(
                          //       ord != null
                          //           ? ord["customer"]["name"]
                          //           : 'Loading...',
                          //       style: TextStyle(
                          //         color: Colors.white,
                          //         fontWeight: FontWeight.bold,
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Account No: ',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    ord != null
                                        ? ord["bank"]["account_number"]
                                        : 'Loading...',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    'IFSC CODE: ',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    ord != null
                                        ? ord["bank"]["ifsc_code"]
                                        : 'Loading...',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Branch: ',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    ord != null
                                        ? ord["bank"]["branch"]
                                        : 'Loading...',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              // Row(
                              //   children: [
                              //     Text(
                              //       'Open Balance: ',
                              //       style: TextStyle(
                              //         color: Colors.grey[400],
                              //         fontSize: 12,
                              //         fontWeight: FontWeight.bold,
                              //       ),
                              //     ),
                              //     Text(
                              //       ord != null
                              //           ? ord["bank"]["open_balance"]
                              //               .toStringAsFixed(
                              //                   2) // Formats to 2 decimal places
                              //           : 'Loading...',
                              //       style: TextStyle(
                              //         color: Colors.grey[400],
                              //         fontSize: 12,
                              //       ),
                              //     ),
                              //   ],
                              // ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 3,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Billing Summary',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Net Amount Before Tax',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${netAmountBeforeTax.toStringAsFixed(2)}', // Format to 2 decimal places
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Discount',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${totalDiscount.toStringAsFixed(2)}', // Format to 2 decimal places
                            style: TextStyle(
                              color: const Color.fromARGB(255, 3, 3, 3),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Tax Amount',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${totalTaxAmount.toStringAsFixed(2)}', // Format to 2 decimal places
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Shipping Charge',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${shippingCharge.toStringAsFixed(2)}', // Format to 2 decimal places
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Payable Amount ',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${actualamount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 1, 155, 24),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  color: Colors.white,
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15.0),
                            topRight: Radius.circular(15.0),
                          ),
                        ),
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Leadger',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: .0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Balance Payment Amount: ',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  ledger
                                      ? "0.0"
                                      : '${Balance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color:
                                          const Color.fromARGB(255, 255, 0, 0)),
                                )
                              ],
                            ),
                            SizedBox(height: 4.0),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "GRV AMOUNT",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${(approvedGrvAmount ?? 0).toStringAsFixed(2)}', // Use null-coalescing operator to handle null
                                )
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "COD GRV AMOUNT",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${(approvedCodReturnAmount ?? 0).toStringAsFixed(2)}', // Use null-coalescing operator to handle null
                                )
                              ],
                            ),
                            SizedBox(height: 4.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Refund AMOUNT",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${(refundReceiptAmount ?? 0).toStringAsFixed(2)}', // Use null-coalescing operator to handle null
                                )
                              ],
                            ),
                            SizedBox(height: 4.0),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      ledger
                                          ? 'Customer Ledger Credit:'
                                          : 'Customer Ledger Debit:',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${(difference ?? 0).toStringAsFixed(2)}',
                                  style: TextStyle(color: Colors.green),
                                )
                              ],
                            ),
                            // if (flag == false)
                            //   Row(
                            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //     children: [
                            //       Text(
                            //         'Customer Ledger Debit:',
                            //         style: TextStyle(
                            //             fontSize: 12,
                            //             fontWeight: FontWeight.bold),
                            //       ),
                            //       Text(
                            //         Balance == 0
                            //             ? '\$${payableAmount.toStringAsFixed(2)}'
                            //             : '\$${Balance.toStringAsFixed(2)}',
                            //       )
                            //     ],
                            //   ),
                            SizedBox(height: 8.0),
                            if (dep != "BDM" && dep != "BDO")
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor:
                                        Colors.blue, // Text color (white)
                                  ),
                                  onPressed: () {
                                    if (createdBy != null) {
                                      showAddDialog(context);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                "Loading data, please wait...")),
                                      );
                                    }
                                  },
                                  child: Text("Add"),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ord != null && ord["recived_payment"].isNotEmpty)
                      Text(
                        'Receipt Details',
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (ord != null && ord["recived_payment"].isNotEmpty)
                      SizedBox(height: 10),
                    if (ord != null && ord["recived_payment"].isNotEmpty)
                      Table(
                        border: TableBorder.all(color: Colors.grey),
                        columnWidths: (dep != "BDM" && dep != "BDO")
                            ? const <int, TableColumnWidth>{
                                0: IntrinsicColumnWidth(),
                                1: FlexColumnWidth(),
                                2: FlexColumnWidth(),
                                3: FlexColumnWidth(),
                                4: FlexColumnWidth(),
                              }
                            : const <int, TableColumnWidth>{
                                0: IntrinsicColumnWidth(),
                                1: FlexColumnWidth(),
                                2: FlexColumnWidth(),
                                3: FlexColumnWidth(),
                              },
                        children: [
                          // Header Row
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Receipt No',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Amount',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Transaction ID',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Received Date',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              if (dep != "BDM" && dep != "BDO")
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Remark',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),

                          // Data Rows
                          for (var receipt in ord["recived_payment"])
                            TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                      receipt["payment_receipt"]?.toString() ??
                                          'N/A'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                      receipt["amount"]?.toString() ?? 'N/A'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                      receipt["transactionID"]?.toString() ??
                                          'N/A'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                      receipt["received_at"]?.toString() ??
                                          'N/A'),
                                ),
                                if (dep != "BDM" && dep != "BDO")
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                        receipt["remark"]?.toString() ?? 'N/A'),
                                  ),
                              ],
                            ),

                          // Total Row
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey[300]),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Total',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  (ord["recived_payment"] as List)
                                      .fold<double>(0.0, (sum, item) {
                                    final amt = item["amount"];
                                    final asDouble = (amt is num)
                                        ? amt.toDouble()
                                        : double.tryParse(
                                                amt?.toString() ?? "0") ??
                                            0.0;
                                    return sum + asDouble;
                                  }).toStringAsFixed(2),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('')),
                              Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('')),
                              if (dep != "BDM" && dep != "BDO")
                                Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text('')),
                            ],
                          ),
                        ],
                      )
                    else
                      Text(
                        'No receipt details available.',
                        style: TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 4,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dep != "BDO")
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(15.0),
                                topRight: Radius.circular(15.0),
                              ),
                            ),
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Update Informations',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (dep != "BDO")
                          SizedBox(
                            height: 10,
                          ),
                        if (dep != "BDO")
                          Builder(
                            builder: (context) {
                              // 🔒 Freeze dropdown during status update
                              final statusItems = isUpdatingStatus
                                  ? [selectedStatus ?? currentOrderStatus]
                                      .whereType<String>()
                                      .toList()
                                  : getFilteredStatuses();

                              return DropdownButtonFormField<String>(
                                value: statusItems.contains(selectedStatus)
                                    ? selectedStatus
                                    : (statusItems.isNotEmpty
                                        ? statusItems.first
                                        : null),
                                items: statusItems
                                    .map(
                                      (s) => DropdownMenuItem<String>(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                                onChanged: isUpdatingStatus
                                    ? null // 🔒 disable change during update
                                    : (value) {
                                        setState(() {
                                          selectedStatus = value;
                                        });
                                      },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Status',
                                ),
                              );
                            },
                          ),
                        if (dep != "BDO") SizedBox(height: 8),
                        if (dep != "BDO")
                          Text("Shipping Address",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        if (dep != "BDO")
                          Padding(
                            padding: const EdgeInsets.only(),
                            child: Container(
                              height: 50,
                              width: MediaQuery.of(context).size.width *
                                  0.9, // Adjust width based on device size
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(width: 20),
                                  Container(
                                    width: MediaQuery.of(context).size.width *
                                        0.7, // Adjust width based on device size
                                    child: InputDecorator(
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: '',
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 1),
                                        ),
                                        child: DropdownButton<int>(
                                          hint: const Text(
                                            'Address',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          value: addres.any((a) =>
                                                  a['id'] == selectedAddressId)
                                              ? selectedAddressId
                                              : null,
                                          isExpanded: true,
                                          underline: Container(),
                                          onChanged: (int? newValue) {
                                            setState(() {
                                              selectedAddressId = newValue;
                                            });
                                          },
                                          items: addres
                                              .map<DropdownMenuItem<int>>(
                                                  (address) {
                                            return DropdownMenuItem<int>(
                                              value: address['id'],
                                              child: Text(
                                                address['address'],
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                            );
                                          }).toList(),
                                        )),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        SizedBox(height: 16.0),
                        //  TextField(
                        //   controller: actualweightController,

                        //   decoration: InputDecoration(
                        //     border: OutlineInputBorder(),
                        //     labelText: 'Add Actual Weight',
                        //   ),
                        // ),

                        // SizedBox(height: 16.0),

                        //  TextField(
                        //   controller: postofficeamountController,

                        //   decoration: InputDecoration(
                        //     border: OutlineInputBorder(),
                        //     labelText: 'Add Post Office Amount',
                        //   ),
                        // ),
                        // SizedBox(height: 16.0),
                        if (dep != "BDO")
                          TextField(
                            controller: shippingchargeController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Add Shipping Charge',
                            ),
                          ),

                        SizedBox(height: 16.0),
                        TextField(
                          controller: accountsnoteController,
                          maxLines: 3,
                          readOnly: (dep == "BDM" || dep == "BDO") &&
                              ord != null &&
                              ord['status'] != 'Invoice Created',
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Add Accounts Note',
                          ),
                        ),
                        SizedBox(height: 10.0),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.blue, // Button background color
                            foregroundColor:
                                Colors.white, // Text (and icon) color
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            // ✅ ALWAYS log status time on submit
                            AddStatusTime(context);

                            // FULL COD → direct update
                            if (selectedStatus == "Invoice Rejected") {
                              updatestatus();
                              return;
                            } else {
                              if (cod_status == "FULL_COD") {
                                updatestatus();
                                return;
                              }

                              if (selectedPayStatus == "credit") {
                                updatestatus();
                                return;
                              }

                              // OTHER COD TYPES → Must have proof image
                              if (selectedImageData.isNotEmpty) {
                                updatestatus();
                                return;
                              }
                            }

                            // No images → show message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Please upload proof image for Payment.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                          child: Text('Submit'),
                        ),

                        if (dep != "BDM" && dep != "BDO")
                          SizedBox(height: 16.0),

                        TextField(
                          controller: noteController,
                          maxLines: 3,
                          readOnly: (dep == "BDM" || dep == "BDO") &&
                              ord != null &&
                              ord['status'] != 'Invoice Created',
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Add a Note',
                          ),
                        ),

                        SizedBox(height: 10.0),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.blue, // Button background color
                            foregroundColor:
                                Colors.white, // Text (and icon) color
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            updatenote();
                          },
                          child: Text('Add Note'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BOX Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10),
                    ord == null || ord['warehouse'] == null
                        ? Center(
                            child: Text(
                              'No BOX Details Available',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Column(
                            children: ord['warehouse'].map<Widget>((order) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    if (dep != "BDM" && dep != "BDO") {
                                      _showShippingChargeDialog(context, order);
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(12.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.3),
                                          spreadRadius: 2,
                                          blurRadius: 4,
                                          offset:
                                              Offset(0, 2), // Shadow position
                                        ),
                                      ],
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Image and Box Details
                                        Row(
                                          children: [
                                            Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                color: Colors.grey[200],
                                              ),
                                              child: order['image'] != null
                                                  ? Image.network(
                                                      '$api${order['image']}',
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            size: 40,
                                                            color: Colors.grey);
                                                      },
                                                    )
                                                  : Icon(
                                                      Icons.image_not_supported,
                                                      size: 40,
                                                      color: Colors.grey),
                                            ),
                                            SizedBox(width: 10),

                                            Expanded(
                                              child: Text(
                                                ' ${order['box'] ?? 'N/A'}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (dep != "BDM" && dep != "BDO")
                                              order['status'] == "Shipped" &&
                                                      order['message_status'] ==
                                                          "pending"
                                                  ? ElevatedButton(
                                                      onPressed: () {
                                                        SendTrackingId(
                                                            context,
                                                            order[
                                                                'tracking_id'],
                                                            order['invoice']);
                                                        updatemsg(order['id']);
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor: Colors
                                                            .blue, // Blue button color
                                                        foregroundColor: Colors
                                                            .white, // White text color
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  12), // Curved border
                                                        ),
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 20,
                                                                vertical:
                                                                    12), // Button padding
                                                      ),
                                                      child: Text(
                                                        "Send Tracking ID",
                                                        style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    )
                                                  : Text(
                                                      "Message Status: ${order['message_status']}",
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey),
                                                    ),
                                            // Delete Button
                                            SizedBox(width: 5),
                                            if (dep != "BDM" && dep != "BDO")
                                              GestureDetector(
                                                onTap: () {
                                                  deletebox(order['id']);
                                                  deleteboxlog(
                                                      context, order['box']);
                                                },
                                                child: Image.asset(
                                                  "lib/assets/close.png",
                                                  height: 15,
                                                  width: 15,
                                                ),
                                              ),
                                          ],
                                        ),
                                        Divider(),
                                        SizedBox(height: 12),

                                        // Shipping Charge
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Packed By:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              order['packed_by'] ?? 'N/A',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 6),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Verified by:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              order['verified_by'] ?? 'N/A',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 6),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Final confirmation:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              order['checked_by'] ?? 'N/A',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Shipping Charge:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              order['shipping_charge'] ?? 'N/A',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Actual Weight:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              order['actual_weight'] != null
                                                  ? '${order['actual_weight']} kg'
                                                  : 'N/A',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Parcel Amount:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              order['parcel_amount'] ?? 'N/A',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 6),

                                        // Parcel Service

                                        SizedBox(height: 6),

                                        GestureDetector(
                                          onTap: () {
                                            if (dep != "BDM" && dep != "BDO") {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    title: Text(
                                                        'Enter Tracking ID'),
                                                    content: TextField(
                                                      controller:
                                                          trackingIdController,
                                                      decoration:
                                                          InputDecoration(
                                                        labelText:
                                                            '${order['tracking_id']}',
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop(); // Close the dialog
                                                        },
                                                        child: Text('Cancel'),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor: Colors
                                                              .blue, // Button background color
                                                          foregroundColor: Colors
                                                              .white, // Button text color
                                                        ),
                                                        onPressed: () {
                                                          String trackingId =
                                                              trackingIdController
                                                                  .text
                                                                  .trim();
                                                          if (trackingId
                                                              .isNotEmpty) {
                                                            updatetrackid(
                                                                trackingId,
                                                                order['id']);
                                                            ;
                                                            Navigator.of(
                                                                    context)
                                                                .pop(); // Close the dialog
                                                          } else {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                    'Please enter a valid Tracking ID'),
                                                                backgroundColor:
                                                                    Colors.red,
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        child: Text('Submit'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            }
                                          },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 16),
                                                decoration: BoxDecoration(
                                                  color: const Color.fromARGB(
                                                      255,
                                                      220,
                                                      220,
                                                      220), // Background color
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8), // Rounded corners
                                                ),
                                                child: Text(
                                                  'Tracking ID',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Colors
                                                        .white, // Text color
                                                  ),
                                                ),
                                              ),
                                              SelectableText(
                                                order['tracking_id'] ?? 'N/A',
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              )
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            showStatusDialog(context, order);
                                          },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 16),
                                                decoration: BoxDecoration(
                                                  color: const Color.fromARGB(
                                                      255,
                                                      220,
                                                      220,
                                                      220), // Background color
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8), // Rounded corners
                                                ),
                                                child: Text(
                                                  'Status',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Colors
                                                        .white, // Text color
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                order['status'] ?? 'N/A',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 6),

                                        GestureDetector(
                                          onTap: () {
                                            if (dep != "BDM" && dep != "BDO") {
                                              showParcelServiceDialog(
                                                  context,
                                                  order['id'],
                                                  order['parcel_service_id']);
                                            }
                                          },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 16),
                                                decoration: BoxDecoration(
                                                  color: const Color.fromARGB(
                                                      255,
                                                      220,
                                                      220,
                                                      220), // Background color
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8), // Rounded corners
                                                ),
                                                child: Text(
                                                  'Parcel Service',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Colors
                                                        .white, // Text color
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                order['parcel_service_name'] !=
                                                            null &&
                                                        order['parcel_service_name']
                                                            .toString()
                                                            .trim()
                                                            .isNotEmpty
                                                    ? order['parcel_service_name']
                                                        .toString()
                                                    : 'N/A',
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: 5,
                                        ),

                                        // Shipped Date
                                        GestureDetector(
                                          onTap: () {
                                            if (dep != "BDM" && dep != "BDO") {
                                              _showDatePicker(
                                                  context, order['id']);
                                            }
                                          },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 16),
                                                decoration: BoxDecoration(
                                                  color: const Color.fromARGB(
                                                      255,
                                                      220,
                                                      220,
                                                      220), // Background color
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8), // Rounded corners
                                                ),
                                                child: Text(
                                                  'Shipped DAte',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Colors
                                                        .white, // Text color
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                order['shipped_date'] ?? 'N/A',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget grvCard() {
    if (grvList.isEmpty) return const SizedBox();

    final List<Map<String, dynamic>> visibleGrvs =
        showAllGrv ? grvList : [grvList.first];

    return Column(
      children: [
        Column(
          children: visibleGrvs.map((grv) {
            return _singleGrvCard(grv);
          }).toList(),
        ),

        // 🔹 SEE MORE / SEE LESS
        if (grvList.length > 1)
          TextButton(
            onPressed: () {
              setState(() {
                showAllGrv = !showAllGrv;
              });
            },
            child: Text(
              showAllGrv ? 'See less' : 'See more',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
      ],
    );
  }

  Widget _singleGrvCard(Map<String, dynamic> grv) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GRV - ${grv['invoice']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D47A1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    grv['date'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🔹 BODY
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _compactRow('Status', grv['status']),
                const SizedBox(height: 6),
                _compactRow('Product', grv['product']),
                const SizedBox(height: 6),
                _compactRow('Qty', grv['quantity'].toString()),
                const SizedBox(height: 6),
                _compactRow('Price', '₹${grv['price']}'),
                const SizedBox(height: 6),
                if (grv['cod_amount'] != null)
                  _compactRow('COD', '₹${grv['cod_amount']}'),
                const SizedBox(height: 6),
                _compactRow('Remark', grv['remark']),
                const SizedBox(height: 6),
                _compactRow('Time', grv['time']),
              ],
            ),
          ),

          // 🔹 NOTE
          if ((grv['note'] ?? '').toString().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFBBDEFB)),
                ),
              ),
              child: Text(
                'Note: ${grv['note']}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _compactRow(String label, String value) {
    final bool isStatus = label.toLowerCase() == 'status';
    final bool isApproved = isStatus && value.toLowerCase() == 'approved';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isStatus ? FontWeight.w600 : FontWeight.normal,
              color: isApproved ? Colors.green : Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
