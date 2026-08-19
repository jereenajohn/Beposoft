import 'dart:convert';
import 'dart:io';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ACCOUNTS/scanner.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/api.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';
import 'package:http_parser/http_parser.dart' show MediaType;

class WarehouseOrderReview extends StatefulWidget {
  final id;
  const WarehouseOrderReview({super.key, required this.id});

  @override
  State<WarehouseOrderReview> createState() => _WarehouseOrderReviewState();
}

class _WarehouseOrderReviewState extends State<WarehouseOrderReview> {
  String getStatusDisplayName(dynamic status) {
    final String value = status?.toString().trim() ?? '';

    switch (value) {
      case 'To Print':
        return 'Delivery Order (DO)';
      case 'Packed':
        return 'Packed For Delivery (PFD)';
      case 'Ready to ship':
        return 'Out For Delivery (OFD)';
      case 'Return From Delivery':
        return 'Return From Delivery';
      default:
        return value;
    }
  }

  Drawer d = Drawer();
  var ord;
  List<Map<String, dynamic>> courierdata = [];

  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> bank = [];
  String? selectedBank;
  int? selectedserviceId;

  String? createdBy;
  var loginid;
  String? companyname;
  DateTime selectedDate = DateTime.now();
  TextEditingController amountController = TextEditingController();
  TextEditingController transactionIdController = TextEditingController();
  TextEditingController remarkController = TextEditingController();
  TextEditingController receivedDateController = TextEditingController();
  String? selectedStatus;
  final TextEditingController noteController = TextEditingController();
  final TextEditingController parcelNoteController = TextEditingController();
  final TextEditingController deliveryReturnReasonController =
      TextEditingController();
  @override
  void initState() {
    super.initState();
    initData();
    getbank();
    getimage();
    receivedDateController.text = DateFormat('dd-MM-yyyy').format(selectedDate);
  }

  Future<void> initData() async {
    await fetchOrderItems();
    await getcourierservices();
    getprofiledata();
    box.text = "Box";
  }

  List<Uint8List> selectedImageslist = [];
  List<Map<String, dynamic>> manager = [];
  String? selectedManagerName;
  int? selectedManagerId;

  final TextEditingController box = TextEditingController();
  final TextEditingController count = TextEditingController();
  final TextEditingController updatebox = TextEditingController();

  final TextEditingController length = TextEditingController();
  final TextEditingController height = TextEditingController();

  final TextEditingController breadth = TextEditingController();
  final TextEditingController weight = TextEditingController();

  final TextEditingController service = TextEditingController();
  final TextEditingController transactionid = TextEditingController();
  final TextEditingController shippingcharge = TextEditingController();

  var famid;
  var staffid;

  double? totalVolume; // Variable to store calculated volume
  final ImagePicker picker = ImagePicker();
  Future<Uint8List> readBytesSafely(XFile file) async {
    final stream = file.openRead();
    final builder = BytesBuilder();

    await for (final chunk in stream) {
      builder.add(chunk);
    }

    return builder.toBytes();
  }

  File? selectedImageFile;
  Uint8List? selectedImageBytes; // store compressed output
  Future<void> selectSingleImage() async {
    try {
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 1800,
        maxWidth: 1800,
        imageQuality: 90,
      );

      if (picked == null) return;

      final file = File(picked.path);

      Uint8List originalBytes = await file.readAsBytes();
      Uint8List compressedBytes = await compressImage(originalBytes);

      // ✅ WRITE COMPRESSED BYTES BACK TO FILE
      final compressedFile = await file.writeAsBytes(
        compressedBytes,
        flush: true,
      );

      setState(() {
        selectedImageFile = compressedFile; // <-- IMPORTANT
        selectedImageBytes = compressedBytes; // for preview
      });
    } catch (e) {}
  }

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
        // Step 1: Read original bytes safely
        Uint8List originalBytes = await readBytesSafely(img);

        // Step 2: COMPRESS the image
        Uint8List compressedBytes = await compressImage(originalBytes);

        // Step 3: Add compressed output
        finalBytes.add(compressedBytes);
      }

      setState(() {
        selectedImageslist = finalBytes;
      });
    } catch (e) {}
  }

  Future<Uint8List> compressImage(Uint8List bytes) async {
    final compressedBytes = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 1080,
      minHeight: 1080,
      quality: 70, // Adjust 0–100 (lower = more compression)
      format: CompressFormat.jpeg,
    );
    return Uint8List.fromList(compressedBytes);
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
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 201) {
        await createlog(
          scaffoldContext: context,
          action: 'Payment images uploaded',
          beforeData: {
            'Action': 'Payment images upload',
          },
          afterData: {
            'Action': 'Payment images uploaded',
            'Image Count': selectedImageslist.length,
          },
        );

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

  Future<void> deleteimage(var Id) async {
    try {
      final token = await getTokenFromPrefs();

      ;
      var response = await http.delete(
        Uri.parse('$api/api/order/images/delete/${Id}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await createlog(
          scaffoldContext: context,
          action: 'Payment image deleted',
          beforeData: {
            'Action': 'Payment image existed',
            'Image ID': Id,
          },
          afterData: {
            'Action': 'Payment image deleted',
            'Image ID': Id,
          },
        );

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

  // Function to calculate volume
  void calculateVolume() {
    final lengthValue = double.tryParse(length.text) ?? 0.0;
    final breadthValue = double.tryParse(breadth.text) ?? 0.0;
    final heightValue = double.tryParse(height.text) ?? 0.0;

    setState(() {
      totalVolume = (lengthValue * breadthValue * heightValue) / 6000;
    });
  }

  File? selectedImage;
  File? selectedImage2;

  final ImagePicker _picker = ImagePicker();

  void imageSelect() async {
    try {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Gallery'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final XFile? pickedFile =
                        await _picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      File? compressed = await compressImageToTargetSize(
                          File(pickedFile.path), 500 * 1024);
                      if (compressed != null) {
                        setState(() {
                          selectedImage = compressed;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Image selected and compressed."),
                          backgroundColor:
                              const Color.fromARGB(173, 120, 249, 126),
                        ));
                      }
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Camera'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final XFile? pickedFile =
                        await _picker.pickImage(source: ImageSource.camera);
                    if (pickedFile != null) {
                      File file =
                          File(pickedFile.path); // 🔄 Convert XFile to File
                      File? compressed = await compressImageToTargetSize(
                          file, 500 * 1024); // 📦 Compress
                      if (compressed != null) {
                        setState(() {
                          selectedImage = compressed;
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error while selecting the image."),
        backgroundColor: Colors.red,
      ));
    }
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

  void imageSelect2() async {
    try {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Gallery'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final XFile? pickedFile =
                        await _picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() {
                        selectedImage2 = File(pickedFile.path);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Image selected from gallery."),
                        backgroundColor: Color.fromARGB(173, 120, 249, 126),
                      ));
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Camera'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final XFile? pickedFile =
                        await _picker.pickImage(source: ImageSource.camera);
                    if (pickedFile != null) {
                      setState(() {
                        selectedImage2 = File(pickedFile.path);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Image captured from camera."),
                        backgroundColor: Color.fromARGB(173, 120, 249, 126),
                      ));
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error while selecting the image."),
        backgroundColor: Colors.red,
      ));
    }
  }

  bool showAllProducts = false;
  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> createlog({
    required BuildContext scaffoldContext,
    required String action,
    dynamic beforeData,
    dynamic afterData,
  }) async {
    final String? token = await getTokenFromPrefs();

    if (token == null || token.trim().isEmpty) {
      debugPrint(
        'Unable to create log for "$action": authentication token not found.',
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
          'before_data': beforeData ??
              {
                'Action': action,
              },
          'after_data': afterData ??
              {
                'Action': action,
              },
          'order': widget.id,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(
          'Log added successfully: $action',
        );
      } else {
        debugPrint(
          'Log creation failed for "$action": '
          '${response.statusCode} - ${response.body}',
        );
      }
    } catch (error) {
      debugPrint(
        'Error creating log for "$action": $error',
      );
    }
  }


  Future<String?> getdepartment() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  final List<String> statuses = [
    'To Print',
    'Packing under progress',
    'Packed',
    'Ready to ship',
    'Return From Delivery',
    'Shipped',
  ];

  List<String> getAvailableOrderStatuses() {
    final String currentStatus =
        ord?['status']?.toString().trim() ?? '';

    switch (currentStatus) {
      case 'To Print':
        return [
          'To Print',
          'Packing under progress',
          'Packed',
          'Ready to ship',
        ];

      case 'Packing under progress':
        return [
          'Packing under progress',
          'Packed',
          'Ready to ship',
        ];

      case 'Packed':
        return [
          'Packed',
          'Ready to ship',
        ];

      case 'Ready to ship':
        final String department =
            dep?.toString().trim().toLowerCase() ?? '';

        final bool canMarkAsShipped =
            department == 'ceo' ||
            department == 'admin' ||
            department == 'coo' ||
            department == 'accounts' ||
            department == 'accounting' ||
            department == 'accounts / accounting' ||
            department == 'warehouse admin';

        return [
          'Ready to ship',
          'Return From Delivery',
          if (canMarkAsShipped) 'Shipped',
        ];

      case 'Return From Delivery':
        return [
          'Return From Delivery',
          'Ready to ship',
        ];

      case 'Shipped':
        return [
          'Shipped',
        ];

      default:
        if (currentStatus.isNotEmpty) {
          return [
            currentStatus,
          ];
        }

        return const [];
    }
  }
  double netAmountBeforeTax = 0.0; // Define at the class level
  double totalTaxAmount = 0.0; // Define at the class level
  double payableAmount = 0.0; // Define at the class level
  double Balance = 0.0; // Define at the class level
  int? selectedAddressId; // Variable to store the selected address ID

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

 Future<void> unlockorder(var id) async {
  final token = await getTokenFromPrefs();

  try {
    final response = await http.post(
      Uri.parse('$api/api/orders/unlock/$id/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({}),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      await createlog(
        scaffoldContext: context,
        action: 'Delivery note unlocked',
        beforeData: {
          'Action': 'Delivery note locked',
          'Order ID': id,
        },
        afterData: {
          'Action': 'Delivery note unlocked',
          'Order ID': id,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Order unlocked successfully',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Return to the EXISTING WarehouseOrderView.
      // Do NOT create WarehouseOrderView(status: null).
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to unlock order',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    debugPrint('UNLOCK ORDER ERROR: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to unlock order. Please try again.',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  Future<void> getprofiledata() async {
    try {
      final token = await getTokenFromPrefs();

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
        });
        getmanagers();
      }
    } catch (error) {}
  }

  Future<void> updatestatus({
    String? deliveryReturnReason,
  }) async {
    try {
      final token = await getTokenFromPrefs();

      final Map<String, dynamic> payload = {
        'status': selectedStatus,
      };

      if (selectedStatus == 'Return From Delivery') {
        final String reason = deliveryReturnReason?.trim() ?? '';

        if (reason.isEmpty) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter delivery return reason'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        payload['delivery_return_reason'] = reason;
      }

      final response = await http.put(
        Uri.parse('$api/api/shipping/${widget.id}/order/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        await createlog(
          scaffoldContext: context,
          action: 'Order status updated',
          beforeData: {
            'Status': ord?['status'],
          },
          afterData: {
            'Status': selectedStatus,
            if (selectedStatus == 'Return From Delivery')
              'Delivery Return Reason': deliveryReturnReason?.trim() ?? '',
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('status updated successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );

        deliveryReturnReasonController.clear();
        await fetchOrderItems();
      } else {
        debugPrint(
          'STATUS UPDATE FAILED: ${response.statusCode} ${response.body}',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update status'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      debugPrint('STATUS UPDATE ERROR: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating status'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleStatusUpdate() async {
    if (selectedStatus == null || selectedStatus!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a status'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedStatus != 'Return From Delivery') {
      await updatestatus();
      return;
    }

    deliveryReturnReasonController.clear();

    final String? reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delivery Return Reason',
          ),
          content: TextField(
            controller: deliveryReturnReasonController,
            autofocus: true,
            maxLines: 4,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Return Reason',
              hintText: 'Enter delivery return reason',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final String enteredReason =
                    deliveryReturnReasonController.text.trim();

                if (enteredReason.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Delivery return reason is required',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop(enteredReason);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    if (!mounted || reason == null || reason.trim().isEmpty) {
      return;
    }

    await updatestatus(
      deliveryReturnReason: reason,
    );
  }

  Future<void> updatecount() async {
    try {
      final token = await getTokenFromPrefs();

      String formattedTime = DateFormat("HH:mm").format(DateTime.now());

      var response = await http.patch(
        Uri.parse('$api/api/order/box/count/${widget.id}/cod/split/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'box_count': count.text,
        }),
      );
      if (response.statusCode == 200) {
        await createlog(
          scaffoldContext: context,
          action: 'Box count updated',
          beforeData: {
            'Box Count': boxCount,
          },
          afterData: {
            'Box Count': count.text,
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('status updated successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => WarehouseOrderReview(id: widget.id)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status'),
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

  List<Map<String, dynamic>> company = [];

  Future<void> getcompany(id) async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/company/getadd/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> companylist = [];

      if (response.statusCode == 200) {
        final productsData = jsonDecode(response.body);

        for (var productData in productsData) {
          String imageUrl = "${productData['image']}";
          companylist.add({
            'id': productData['id'],
            'name': productData['name'],
          });

          if (id == productData['id']) {
            companyname = productData['name'];
          }
        }

        setState(() {
          company = companylist;
        });
      }
    } catch (error) {}
  }

  Future<void> getcourierservices() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/parcal/service/'),
        headers: {
          'Authorization': ' Bearer $token',
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
      }
    } catch (error) {}
  }

  Future<void> updateverifiedby(var orderId, selectedManagerId) async {
    try {
      ;
      final token = await getTokenFromPrefs();

      ;
      var response = await http.put(
        Uri.parse('$api/api/warehouse/detail/$orderId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'verified_by': selectedManagerId,
          },
        ),
      );
      ;
      ;
      if (response.statusCode == 200) {
        await createlog(
          scaffoldContext: context,
          action: 'Box verification updated',
          beforeData: {
            'Action': 'Verification update requested',
            'Warehouse Box ID': orderId,
          },
          afterData: {
            'Verified By': selectedManagerId,
            'Warehouse Box ID': orderId,
          },
        );

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

  Future<void> updateboxstatus(var orderId) async {
    try {
      final token = await getTokenFromPrefs();

      ;
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
        await createlog(
          scaffoldContext: context,
          action: 'Box status updated',
          beforeData: {
            'Action': 'Previous box status',
            'Warehouse Box ID': orderId,
          },
          afterData: {
            'Status': selectedStatus,
            'Warehouse Box ID': orderId,
          },
        );

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

  Future<void> deletebox(var orderId) async {
    try {
      ;
      final token = await getTokenFromPrefs();

      var response = await http.delete(
        Uri.parse('$api/api/warehouse/detail/$orderId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await createlog(
          scaffoldContext: context,
          action: 'Warehouse box deleted',
          beforeData: {
            'Action': 'Warehouse box existed',
            'Warehouse Box ID': orderId,
          },
          afterData: {
            'Action': 'Warehouse box deleted',
            'Warehouse Box ID': orderId,
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to Delete'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      fetchOrderItems();
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

  Future<void> getmanagers() async {
    try {
      final token = await getTokenFromPrefs();
      var dep = await getdepartment();
      var response = await http.get(
        Uri.parse('$api/api/staffs/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> managerlist = [];
      ;
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          if (productData['department_name'] != "BDM" &&
              productData['department_name'] != "BDO" &&
              productData['department_name'] != "Marketing" &&
              productData['department_name'] != "CSO" &&
              productData['department_name'] != "CEO" &&
              productData['department_name'] != "HR" &&
              productData['department_name'] != "IT") {
            managerlist.add({
              'id': productData['id'],
              'name': productData['name'],
            });
          }
          // else{

          //   managerlist.add({
          //   'id': productData['id'],
          //   'name': productData['name'],
          // });

          // }
        }
        setState(() {
          manager = managerlist;
        });
      }
    } catch (error) {}
  }

  Widget _detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value?.toString() ?? 'N/A',
            ),
          ],
        ),
        softWrap: true,
      ),
    );
  }

  Widget _imagePreview(String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: double.infinity,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 120,
            color: Colors.grey.shade200,
            child: const Icon(Icons.image_not_supported,
                size: 40, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  void showBoxDetailsDialog(
      BuildContext context, Map<String, dynamic> boxDetails) {
    int? selectedManagerId;
    String? selectedManagerName;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: const Text(
            'Box Details',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Box', boxDetails['box']),
                  _detailRow('Packed By', boxDetails['packed_by']),
                  _detailRow('Shipping Charge', boxDetails['shipping_charge']),
                  _detailRow('Parcel Service', boxDetails['parcel_service']),
                  _detailRow('Tracking ID', boxDetails['tracking_id']),
                  _detailRow('Status', getStatusDisplayName(boxDetails['status'])),
                  _detailRow('Shipped Date', boxDetails['shipped_date']),

                  const SizedBox(height: 10),

                  if (boxDetails['image'] != null)
                    _imagePreview('$api${boxDetails['image']}'),

                  if (boxDetails['image_before'] != null)
                    _imagePreview('$api${boxDetails['image_before']}'),

                  const SizedBox(height: 16),

                  /// 🔹 Verify By Dropdown
                  DropdownButtonFormField<Map<String, dynamic>>(
                    isExpanded: true, // ✅ CRITICAL FIX
                    value: selectedManagerId != null
                        ? manager.firstWhere(
                            (e) => e['id'] == selectedManagerId,
                            orElse: () => manager.first,
                          )
                        : null,
                    hint: const Text('Select here...'),
                    items: manager.map((m) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: m,
                        child: Text(
                          m['name'],
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedManagerName = val!['name'];
                        selectedManagerId = val['id'];
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Verify By',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () {
                updateverifiedby(boxDetails['id'], selectedManagerId);
                Navigator.of(context).pop();
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void Editbox(var order, BuildContext context) {
    updatebox.text = order['box'] ?? '';
    length.text = order['length']?.toString() ?? '';
    breadth.text = order['breadth']?.toString() ?? '';
    height.text = order['height']?.toString() ?? '';
    weight.text = order['weight']?.toString() ?? '';
    selectedStatus = order['status'] ?? 'Packing under progress';
    selectedManagerId = order['packed_by_id'] != null
        ? (order['packed_by_id'] is int
            ? order['packed_by_id']
            : int.tryParse(order['packed_by_id'].toString()))
        : null;
    selectedserviceId = ord != null && ord['parcel_service'] != null
        ? int.tryParse(ord['parcel_service'].toString())
        : null;

    parcelNoteController.text =
        ord != null ? ord['parcel_service_note']?.toString() ?? '' : '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text('Enter Box Details', style: TextStyle(fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Manager Dropdown
                  Container(
                    height: 45,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: DropdownButton<Map<String, dynamic>>(
                      value: manager.isNotEmpty
                          ? manager.firstWhere(
                              (element) =>
                                  element['id'] ==
                                  (selectedManagerId ?? manager[0]['id']),
                              orElse: () => manager[0],
                            )
                          : null,
                      underline: SizedBox(),
                      onChanged: manager.isNotEmpty
                          ? (Map<String, dynamic>? newValue) {
                              setState(() {
                                selectedManagerName = newValue!['name'];
                                selectedManagerId = newValue['id'];
                              });
                            }
                          : null,
                      items: manager
                          .map<DropdownMenuItem<Map<String, dynamic>>>(
                              (Map<String, dynamic> manager) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: manager,
                          child: Text(
                            manager['name'],
                            style: TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      isExpanded: true,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Length & Breadth Fields
                  TextField(
                    controller: updatebox,
                    decoration: InputDecoration(
                      labelText: 'Boxes',
                      labelStyle: TextStyle(fontSize: 13),
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: length,
                          decoration: InputDecoration(
                            labelText: 'Length',
                            labelStyle: TextStyle(fontSize: 13),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => calculateVolume(),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: breadth,
                          decoration: InputDecoration(
                            labelText: 'Breadth',
                            labelStyle: TextStyle(fontSize: 13),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => calculateVolume(),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Height & Weight Fields
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: height,
                          decoration: InputDecoration(
                            labelText: 'Height',
                            labelStyle: TextStyle(fontSize: 13),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => calculateVolume(),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: weight,
                          decoration: const InputDecoration(
                            labelText: 'Weight(g)',
                            labelStyle: TextStyle(fontSize: 13),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly, // Allow only whole numbers
                          ],
                        ),
                      )
                    ],
                  ),

                  if (totalVolume != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Total Volume: ${totalVolume!.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  SizedBox(height: 8),

                  // Parcel Service Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1.0),
                    ),
                    child: DropdownButton<int>(
                      isExpanded: true,
                      underline: SizedBox(),
                      hint: Text('Select a Parcel Service'),
                      value: selectedserviceId,
                      items: courierdata.map((item) {
                        return DropdownMenuItem<int>(
                          value: item['id'],
                          child: Text(item['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedserviceId = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      parcelNoteController.text.isNotEmpty
                          ? parcelNoteController.text
                          : 'No note',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),

                  SizedBox(height: 8),

                  // Status Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    hint: Text('Select Status'),
                    items: statuses.map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(getStatusDisplayName(status)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Status',
                    ),
                  ),
                  SizedBox(height: 8),

                  // Date Picker
                  Container(
                    height: 50,
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: TextStyle(fontSize: 13),
                        ),
                        Spacer(),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Icon(Icons.date_range, size: 20),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 8),
                  InkWell(
                    onTap: () => selectSingleImage(),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: selectedImageBytes == null
                          ? Center(
                              child: Text(
                                'Image after Packing',
                                style: TextStyle(fontSize: 13),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                selectedImageBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 12),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
               onPressed: () async {
  Navigator.pop(context);

  await updateOrderParcelService();

  updateboxdetails(
    order,
    selectedImageFile,
    null,
    selectedDate,
    context,
  );
},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // 👈 Button color
                  foregroundColor: Colors.white, // 👈 Text/icon color
                ),
                child: Text('Submit'),
              ),
            ],
          );
        });
      },
    );
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
          'before_data': {"status": "N/A"},
          'after_data': {"status": "Created ${box.text}"},
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

  Future<void> Addboxcount(BuildContext scaffoldContext) async {
    final token = await gettoken();
    try {
      final response = await http.post(
        Uri.parse('$api/api/datalog/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'before_data': {"status": "Box count added"},
          'after_data': {"status": "Count: ${count.text}"},
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

  void addboxdetails(
    File? image1,
    File? image2,
    DateTime selectedDate,
    BuildContext scaffoldContext,
  ) async {
    final token = await getTokenFromPrefs();
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$api/api/warehouse/data/'));

      // Add headers to the request
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields directly
      request.fields['shipped_date'] =
          selectedDate.toIso8601String().substring(0, 10);
      request.fields['order'] =
          widget.id.toString(); // Ensure widget.id is a string
      request.fields['box'] = box.text; // Assuming box.text is already a string

      breadth.text.toString(); // Ensure breadth is a string
      if (selectedserviceId != null) {
        request.fields['parcel_service'] = selectedserviceId.toString();
      } else {
        request.fields['parcel_service'] = courierdata[0]['id'].toString();
      }

      request.fields['tracking_id'] =
          transactionid.text; // Assuming transactionid.text is already a string
      // request.fields['shipping_charge'] =
      //     shippingcharge.text.toString(); // Ensure shipping charge is a string

      if (selectedManagerId == null) {
        request.fields['packed_by'] =
            loginid.toString(); // Convert selectedManagerId to String
      } else {
        request.fields['packed_by'] =
            selectedManagerId.toString(); // Convert selectedManagerId to String
      }

      // Add images to the request if they are not null
      if (image1 != null) {
        request.files
            .add(await http.MultipartFile.fromPath('image', image1.path));
      }
      if (image2 != null) {
        request.files.add(
            await http.MultipartFile.fromPath('image_before', image2.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Handle response based on status code
      if (response.statusCode == 201) {
        await createlog(
          scaffoldContext: scaffoldContext,
          action: 'Warehouse box added',
          beforeData: {
            'Action': 'New warehouse box',
          },
          afterData: {
            'Box': box.text,
            'Tracking ID': transactionid.text,
            'Parcel Service': selectedserviceId,
            'Packed By': selectedManagerId ?? loginid,
            'Shipped Date':
                selectedDate.toIso8601String().substring(0, 10),
          },
        );

        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Data Added Successfully.'),
          ),
        );
        Navigator.pushReplacement(
          scaffoldContext,
          MaterialPageRoute(
            builder: (context) => WarehouseOrderReview(
              id: widget.id,
            ),
          ),
        );
      } else {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ??
                'Something went wrong. Please try again later.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(content: Text('Network error. Please check your connection.')),
      );
    }
  }

 Future<bool> updateOrderParcelService() async {
  try {
    final token = await getTokenFromPrefs();

    final response = await http.put(
      Uri.parse('$api/api/shipping/${widget.id}/order/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'parcel_service': selectedserviceId,
        'parcel_service_note': parcelNoteController.text.trim(),
      }),
    );

    if (response.statusCode == 200) {
      await createlog(
        scaffoldContext: context,
        action: 'Parcel service updated',
        beforeData: {
          'Parcel Service': ord?['parcel_service'],
          'Parcel Service Note': ord?['parcel_service_note'],
        },
        afterData: {
          'Parcel Service': selectedserviceId,
          'Parcel Service Note': parcelNoteController.text.trim(),
        },
      );

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
      debugPrint('Parcel service update failed: ${response.statusCode}');
      debugPrint('Response: ${response.body}');

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
  } catch (e) {
    debugPrint('Parcel service update error: $e');

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

  void updateboxdetails(
    var order,
    File? image1,
    File? image2,
    DateTime selectedDate,
    BuildContext scaffoldContext,
  ) async {
    final token = await getTokenFromPrefs();

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$api/api/warehouse/detail/${order['id']}/'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['shipped_date'] =
          selectedDate.toIso8601String().substring(0, 10);

      request.fields['order'] = widget.id.toString();
      request.fields['box'] = updatebox.text;
      request.fields['length'] = length.text.toString();
      request.fields['height'] = height.text.toString();
      request.fields['weight'] = weight.text.toString();
      request.fields['breadth'] = breadth.text.toString();

      if (selectedserviceId != null) {
        request.fields['parcel_service'] = selectedserviceId.toString();
      }

      request.fields['parcel_service_note'] = parcelNoteController.text.trim();
      request.fields['status'] = selectedStatus ?? '';

      if (selectedManagerId == null) {
        request.fields['packed_by'] = loginid.toString();
      } else {
        request.fields['packed_by'] = selectedManagerId.toString();
      }

      // ---------------------------------------------------------
      // NEW: COMPRESSED IMAGE UPLOAD (ONLY THIS PART IS CHANGED)
      // ---------------------------------------------------------

      if (image1 != null) {
        Uint8List original = await image1.readAsBytes();
        Uint8List compressed = await compressImage(original);

        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            compressed,
            filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      if (image2 != null) {
        Uint8List original = await image2.readAsBytes();
        Uint8List compressed = await compressImage(original);

        request.files.add(
          http.MultipartFile.fromBytes(
            'image_before',
            compressed,
            filename:
                'image_before_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      // ---------------------------------------------------------

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        await createlog(
          scaffoldContext: scaffoldContext,
          action: 'Warehouse box details updated',
          beforeData: {
            'Warehouse Box ID': order['id'],
            'Box': order['box'],
            'Length': order['length'],
            'Breadth': order['breadth'],
            'Height': order['height'],
            'Weight': order['weight'],
            'Status': order['status'],
          },
          afterData: {
            'Warehouse Box ID': order['id'],
            'Box': updatebox.text,
            'Length': length.text,
            'Breadth': breadth.text,
            'Height': height.text,
            'Weight': weight.text,
            'Status': selectedStatus,
            'Parcel Service': selectedserviceId,
            'Parcel Service Note': parcelNoteController.text.trim(),
            'Packed By': selectedManagerId ?? loginid,
          },
        );

        fetchOrderItems();

        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Data Added Successfully.'),
          ),
        );

        Navigator.pushReplacement(
          scaffoldContext,
          MaterialPageRoute(
            builder: (context) => WarehouseOrderReview(id: widget.id),
          ),
        );
      } else {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ??
                'Something went wrong. Please try again later.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(content: Text('Network error. Please check your connection.')),
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
                    child: Text(getStatusDisplayName(status)),
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

  void showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
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
                      selectedBank = value; // Update selected bank
                    });
                  },
                  decoration: InputDecoration(labelText: 'Bank'),
                ),
                TextField(
                  controller: transactionIdController,
                  decoration: InputDecoration(
                      labelText: 'Tracking ID',
                      prefixIcon: Icon(Icons.receipt)),
                ),
                TextField(
                  readOnly: true, // Make this field non-editable
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person),
                    hintText:
                        createdBy ?? 'Loading...', // Display the creator's name
                  ),
                ),

                TextField(
                  controller: remarkController,
                  decoration: InputDecoration(labelText: 'Remark (optional)'),
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

                AddReceipt(context);
              },
              child: Text('Save'),
            ),
          ],
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
    try {
      final token = await gettoken();

      var response = await http.put(
        Uri.parse('$api/api/shipping/${widget.id}/order/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/jso',
        },
        body: jsonEncode(
          {
            'status': selectedStatus,
            'billing_address': selectedAddressId,
            'note': noteController.text,
          },
        ),
      );

      if (response.statusCode == 200) {
        await createlog(
          scaffoldContext: context,
          action: 'Order address updated',
          beforeData: {
            'Billing Address': ord?['billing_address'],
            'Note': ord?['note'],
          },
          afterData: {
            'Billing Address ID': selectedAddressId,
            'Note': noteController.text,
            'Status': selectedStatus,
          },
        );

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
              builder: (context) => WarehouseOrderReview(id: widget.id)),
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

  // ...existing code...

  List<Map<String, dynamic>> selectedImageData =
      []; // Replace your previous selectedImageUrls list

  Future<void> getimage() async {
    final token = await gettoken();
    try {
      final response = await http.get(
        Uri.parse('$api/api/order/images/${widget.id}/'),
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

// ...existing code...
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
        await createlog(
          scaffoldContext: scaffoldContext,
          action: 'Receipt added',
          beforeData: {
            'Action': 'Receipt creation',
          },
          afterData: {
            'Amount': amountController.text,
            'Bank': selectedBank,
            'Tracking ID': transactionIdController.text,
            'Received At': formattedReceivedDate,
            'Created By': createdBy,
            'Remark': remarkController.text,
          },
        );

        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Receipt added Successfully.'),
          ),
        );
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => WarehouseOrderReview(
                      id: widget.id,
                    )));
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

  int boxCount = 0;

  bool flag = false;
  var dep;
  double totalDiscount = 0.0; // Define at the class level
  Future<void> fetchOrderItems() async {
    try {
      final token = await getTokenFromPrefs();
      dep = await getdepartment();
      final jwt = JWT.decode(token!);
      var name = jwt.payload['id'];
      setState(() {
        selectedManagerId = name;
      });

      ;
      var response = await http.get(
        Uri.parse('$api/api/order/${widget.id}/items/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      ;

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        ord = parsed['order'];
        int fetchedBoxCount =
            int.tryParse(parsed['order']['box_count']?.toString() ?? '0') ?? 0;

        List<dynamic> itemsData = parsed['items'];
        getaddress(ord['customer']['id']);
        int? selectedAddressId; // Variable to store the selected address ID

        List<Map<String, dynamic>> orderList = [];
        double calculatedNetAmount = 0.0;
        double calculatedTotalTax = 0.0;
        double calculatedPayableAmount = 0.0;
        double calculatedTotalDiscount = 0.0;

        // Process each item and calculate totals
        for (var item in itemsData) {
          orderList.add({
            'id': item['id'],
            'name': item['name'],
            'quantity': item['quantity'],
            'rate': item['rate'],
            'tax': item['tax'],
            'discount': item['discount'],
            'actual_price': item['actual_price'],
            'exclude_price': item['exclude_price'],
            'images': item['image'],
            'image_before': item['image_before'],
          });

          // Convert values to double for safe calculation
          double excludePrice =
              double.tryParse(item['exclude_price'].toString()) ?? 0.0;
          double actualPrice =
              double.tryParse(item['actual_price'].toString()) ?? 0.0;
          double discount = double.tryParse(item['discount'].toString()) ?? 0.0;

          final quantity = int.tryParse(item['quantity'].toString()) ??
              1; // Ensure it's an integer

          // Add the exclude_price to net amount
          calculatedNetAmount += excludePrice;

          // Calculate and add the tax amount for each product
          double taxAmountForItem = actualPrice - excludePrice;
          calculatedTotalTax += taxAmountForItem;

          // Add discount amount for each product
          calculatedTotalDiscount += discount * quantity;

          // Calculate payable amount after subtracting discount
          double payableForItem = (actualPrice - discount) * quantity;
          calculatedPayableAmount += payableForItem;
        }

        // Calculate the sum of payment receipts
        double paymentReceiptsSum = 0.0;
        for (var receipt in parsed['order']['recived_payment']) {
          paymentReceiptsSum +=
              double.tryParse(receipt['amount'].toString()) ?? 0.0;
        }

        // Calculate remaining amount after comparing with calculatedPayableAmount
        double remainingAmount = 0.0;
        if (paymentReceiptsSum > calculatedPayableAmount) {
          remainingAmount = paymentReceiptsSum - calculatedPayableAmount;
          flag = true;
        } else {
          remainingAmount = calculatedPayableAmount - paymentReceiptsSum;
          flag = false;
        }
        // getcompany(ord['company']);

        setState(() {
          items = orderList;
          netAmountBeforeTax = calculatedNetAmount;
          totalTaxAmount = calculatedTotalTax;
          payableAmount = calculatedPayableAmount;
          totalDiscount = calculatedTotalDiscount;
          Balance = remainingAmount;
          boxCount = fetchedBoxCount;

          // Always show the current order status in the Select Status field.
          final String currentStatus =
              ord?['status']?.toString().trim() ?? '';

          selectedStatus =
              currentStatus.isNotEmpty ? currentStatus : null;
        });
      } else {}
    } catch (error) {}
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

  void showPopupDialog(BuildContext context, Map<String, dynamic> item) {
    TextEditingController quantityController =
        TextEditingController(text: item['quantity']?.toString() ?? '');
    TextEditingController discountController =
        TextEditingController(text: item['discount']?.toString() ?? '');

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

                updatedetails(item['id'], quantity, discount);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updatedetails(int id, int quantity, double discount) async {
    try {
      final token = await getTokenFromPrefs();
      final response = await http.put(
        Uri.parse('$api/api/remove/order/$id/item/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'quantity': quantity,
          'discount': discount,
        }),
      );

      if (response.statusCode == 200) {
        await createlog(
          scaffoldContext: context,
          action: 'Order item updated',
          beforeData: {
            'Order Item ID': id,
          },
          afterData: {
            'Order Item ID': id,
            'Quantity': quantity,
            'Discount': discount,
          },
        );

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


  @override
  Widget build(BuildContext context) {
    final visibleItems = showAllProducts ? items : items.take(2).toList();
    return WillPopScope(
      onWillPop: () async {
               Navigator.pop(context);
        
        // Trigger the navigation logic when the back swipe occurs
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
    /// 🔹 Back Button
 IconButton(
  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
  onPressed: () {
    Navigator.pop(context);
  },
),

    const SizedBox(width: 5),

    /// 🔹 Icon Container
    Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 220, 220, 220),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.local_shipping,
        size: 32,
        color: Colors.blue,
      ),
    ),

    const SizedBox(width: 10),

    /// 🔹 Invoice Details
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ord != null
              ? ord['invoice'] ?? 'Invoice Number'
              : 'Loading...',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    ),
  ],
),
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      ord != null
                          ? ord['company']['name'] ?? 'Company'
                          : 'Loading...',
                      style: TextStyle(color: Colors.black),
                    ),
                    SizedBox(
                      height: 5,
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                color: Colors.white, // Background color
                padding: EdgeInsets.all(10), // Add padding
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly, // Evenly space buttons
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final Uri url =
                            Uri.parse('$api/deliverynote/${ord['id']}/');

                        if (!await launchUrl(url,
                            mode: LaunchMode.externalApplication)) {
                          // Handle error case
                        }
                      },
                      icon: Icon(
                        Icons.download,
                        color: Colors.white,
                      ), // Download icon
                      label: Text("Delivery"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Button color
                        foregroundColor: Colors.white, // Text color
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final Uri url =
                            Uri.parse('$api/shippinglabel/${ord['id']}/');

                        if (!await launchUrl(url,
                            mode: LaunchMode.externalApplication)) {
                          // Handle error case
                        }
                      },
                      icon: Icon(Icons.download,
                          color: Colors.white), // Download icon
                      label: Text("Address"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Button color
                        foregroundColor: Colors.white, // Text color
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      unlockorder(ord['id']);
                    },
                    icon: Icon(Icons.download,
                        color: Colors.white), // Download icon
                    label: Text("Unlock Delivery Note"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Button color
                      foregroundColor: Colors.white, // Text color
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
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
                            Text(
                              ord != null
                                  ? ord["order_date"] ?? 'Date Not Available'
                                  : '',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
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
                                      ? getStatusDisplayName(ord["status"])
                                      : 'Loading...',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Family',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                Spacer(),
                                Text(
                                  ord != null
                                      ? '${ord["family"]}'
                                      : 'Loading...',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.0),
                            SizedBox(height: 4.0),
                            if (ord != null && ord['shipping_mode'] != null)
                              Row(
                                children: [
                                  Text(
                                    'Shipping Mode',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Spacer(),
                                  Text(
                                    '${ord['shipping_mode']}',
                                    style: TextStyle(
                                        color:
                                            const Color.fromARGB(255, 0, 0, 0),
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            if (ord != null &&
                                ord['code_charge'] != null &&
                                ord['code_charge'] != 0)
                              SizedBox(height: 4.0),
                            if (ord != null &&
                                ord['code_charge'] != null &&
                                ord['code_charge'] != 0)
                              Row(
                                children: [
                                  Text(
                                    'Code Charge',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Spacer(),
                                  Text(
                                    ' ${ord['code_charge']}',
                                    style: TextStyle(
                                        color:
                                            const Color.fromARGB(255, 0, 0, 0),
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, top: 10),
                child: DropdownButtonFormField<String>(
                  value: selectedStatus,
                  hint: const Text('Select Status'),
                  items: getAvailableOrderStatuses().map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(
                        getStatusDisplayName(status),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                height: 5,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _handleStatusUpdate();
                  },
                  label: Text("Save"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Button color
                    foregroundColor: Colors.white, // Text color
                  ),
                ),
              ),

              if (ord != null &&
                  ord['delivery_return_reason'] != null &&
                  ord['delivery_return_reason'].toString().trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 8,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      border: Border.all(
                        color: const Color(0xFFF97316).withOpacity(0.30),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Return Reason',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9A3412),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          ord['delivery_return_reason'].toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7C2D12),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Billing Address',
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
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
                      ord != null
                          ? '${ord["billing_address"]["name"]}'
                          : 'Loading...',
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
                      'Products',
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),

                    // Display each item in the visibleItems list within a card
                   for (var item in visibleItems)
  Card(
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
                                        'Rate After Discount: ${(double.tryParse(item["rate"].toString()) ?? 0.0) - (double.tryParse(item["discount"].toString()) ?? 0.0)}',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),

                                      Text(
                                        'Tax Amount: ${(((double.tryParse(item["rate"].toString()) ?? 0.0) - (double.tryParse(item["discount"].toString()) ?? 0.0)) - (double.tryParse(item["exclude_price"].toString()) ?? 0.0)).toStringAsFixed(2)}',
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
                                            'Total: ₹${(((double.tryParse(item["exclude_price"].toString()) ?? 0.0) + (((double.tryParse(item["rate"].toString()) ?? 0.0) - (double.tryParse(item["discount"].toString()) ?? 0.0)) - (double.tryParse(item["exclude_price"].toString()) ?? 0.0))) * (int.tryParse(item["quantity"].toString()) ?? 1)).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
              SizedBox(
                height: 10,
              ),
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Container(
//                   padding: const EdgeInsets.all(8.0),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(8.0),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.grey.withOpacity(0.3),
//                         spreadRadius: 2,
//                         blurRadius: 5,
//                         offset: Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       if (selectedImageslist.isNotEmpty) Text("Images"),
//                       if (selectedImageslist.isNotEmpty) SizedBox(height: 8),
//                       // Only show the image list if there are selected images
//                     if (selectedImageData.isNotEmpty)
//   SizedBox(
//     height: 60,
//     child: ListView.builder(
//       scrollDirection: Axis.horizontal,
//       itemCount: selectedImageData.length,
//       itemBuilder: (context, index) {
//         final imageItem = selectedImageData[index];

//         return Stack(
//           children: [
//             // Image with padding
//            GestureDetector(
//   onTap: () {
//     showDialog(
//       context: context,
//       builder: (_) => Dialog(
//         backgroundColor: Colors.transparent,
//         child: GestureDetector(
//           onTap: () => Navigator.pop(context),
//           child: InteractiveViewer(
//             child: Image.network(imageItem['imageUrl']),
//           ),
//         ),
//       ),
//     );
//   },
//   child: Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 4.0),
//     child: ClipRRect(
//       borderRadius: BorderRadius.circular(8),
//       child: Image.network(
//         imageItem['imageUrl'],
//         width: 60,
//         height: 60,
//         fit: BoxFit.cover,
//         errorBuilder: (context, error, stackTrace) {
//           return const SizedBox.shrink();
//         },
//       ),
//     ),
//   ),
// ),

//             // Close Icon
//             Positioned(
//               top: 2,
//               right: 2,
//               child: GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     deleteimage(imageItem['id']);
//                   });
//                 },
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.6),
//                     shape: BoxShape.circle,
//                   ),
//                   padding: const EdgeInsets.all(2),
//                   child: const Icon(
//                     Icons.close,
//                     color: Colors.white,
//                     size: 16,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     ),
//   ),

//                       SizedBox(height: 8),
//                       if (selectedImageslist.isNotEmpty)
//                         Text("Selected Images"),

//                       if (selectedImageslist.isNotEmpty)
//                         SizedBox(
//                           height: 70,
//                           child: ListView.builder(
//                             scrollDirection: Axis.horizontal,
//                             itemCount: selectedImageslist.length,
//                             itemBuilder: (context, index) {
//                               return Stack(
//                                 children: [
//                                   // Image Thumbnail with Padding
//                                   Padding(
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 4.0),
//                                     child: ClipRRect(
//                                       borderRadius: BorderRadius.circular(8),
//                                       child: Image.memory(
//                                         selectedImageslist[index],
//                                         width: 60,
//                                         height: 60,
//                                         fit: BoxFit.cover,
//                                       ),
//                                     ),
//                                   ),

//                                   // Positioned Close Icon
//                                   Positioned(
//                                     top: 2,
//                                     right: 2,
//                                     child: GestureDetector(
//                                       onTap: () {
//                                         setState(() {
//                                           selectedImageslist.removeAt(index);
//                                         });
//                                       },
//                                       child: Container(
//                                         decoration: BoxDecoration(
//                                           color: Colors.black.withOpacity(0.6),
//                                           shape: BoxShape.circle,
//                                         ),
//                                         padding: const EdgeInsets.all(2),
//                                         child: Icon(
//                                           Icons.close,
//                                           color: Colors.white,
//                                           size: 16,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               );
//                             },
//                           ),
//                         ),

//                       SizedBox(height: 8),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           ElevatedButton.icon(
//                             onPressed: selectMultipleImages,
//                             icon: Icon(Icons.add_a_photo, color: Colors.black),
//                             label: Text(
//                               "Add Images",
//                               style: TextStyle(color: Colors.black),
//                             ),
//                             style: ElevatedButton.styleFrom(
//                                 backgroundColor:
//                                     const Color.fromARGB(255, 218, 218, 218)),
//                           ),
//                           ElevatedButton(
//                             onPressed: () {
//                               addimages(context);
//                             },
//                             child: Text(
//                               "Submit Images",
//                               style: TextStyle(color: Colors.white),
//                             ),
//                             style: ElevatedButton.styleFrom(
//                                 backgroundColor:
//                                     const Color.fromARGB(255, 0, 168, 65)),
//                           ),
//                         ],
//                       ),
//                       // ...existing code...
//                     ],
//                   ),
//                 ),
//               ),
              SizedBox(height: 10),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// 🔹 Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.inventory_2_outlined,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                "Box Count",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        /// 🔹 Input Field
                        Text(
                          "Enter Box Count",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 6),

                        TextField(
                          controller: count,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            // hintText: 'e.g. 2',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// 🔹 Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              Addboxcount(context);
                              updatecount();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Save Box Count",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        /// 🔹 Current Box Count Display
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Current Box Count: $boxCount',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // Reduced padding
                  child: Container(
                    padding: const EdgeInsets.all(12.0), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(8.0), // Reduced border radius
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 3,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 40, // Reduced height
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: Colors.blue,
                          ),
                          alignment: Alignment.center, // Simplified layout
                          child: Text(
                            "Box Details",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15, // Reduced font size
                            ),
                          ),
                        ),
                        SizedBox(height: 8), // Reduced spacing

                        SizedBox(height: 8),
                        TextField(
                          controller: box,
                          decoration: InputDecoration(
                            labelText: 'Boxes',
                            labelStyle: TextStyle(fontSize: 13),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                          ),
                        ),
                        SizedBox(height: 8), // Reduced spacing

                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: transactionid,
                                decoration: InputDecoration(
                                  labelText: 'Tracking Id',
                                  labelStyle: TextStyle(fontSize: 13),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 8.0),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            // IconButton(
                            //   icon: Icon(Icons.qr_code_scanner,
                            //       size: 28, color: Colors.blue),
                            //   onPressed: () async {
                            //     await Navigator.push(
                            //       context,
                            //       MaterialPageRoute(
                            //         builder: (context) => BarcodeScannerPage(
                            //           onScan: (value) {
                            //             transactionid.text = value;
                            //           },
                            //         ),
                            //       ),
                            //     );
                            //   },
                            // ),
                          ],
                        ),

                        SizedBox(height: 8),

                        SizedBox(height: 12), // Reduced spacing

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                AddStatusTime(context);

                                addboxdetails(selectedImage, selectedImage2,
                                    selectedDate, context);
                                //updatestatus();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.blue, // Button background color
                                foregroundColor: Colors.white, // Text color
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15), // Padding inside the button
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      10), // Rounded corners
                                ),
                                elevation: 5, // Shadow effect
                                fixedSize: Size(
                                    200, 50), // Width and height of the button
                              ),
                              child: Text(
                                "Submit",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.bold), // Text styling
                              ),
                            ),
                          ],
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
                      'BOXS',
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
                                    if (dep != "warehouse") {
                                      showBoxDetailsDialog(context, order);
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
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                              ),
                                              onPressed: () {
                                                Editbox(order, context);
                                              },
                                              child: Text('Views',
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                            ),
                                            SizedBox(width: 15),
                                            // Delete Button
                                            if (dep != "warehouse")
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

                                        SizedBox(height: 10),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Weight:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              order['weight'] ?? 'N/A',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            Text(
                                              'Length:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              order['length'] ?? 'N/A',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            Text(
                                              'Breadth:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              order['breadth'] ?? 'N/A',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            Text(
                                              'Height:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              order['height'] ?? 'N/A',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        Divider(),

                                        SizedBox(height: 4),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Packed By:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              order['packed_by'] ?? 'N/A',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),

                                        SizedBox(height: 4),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Verified by:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              order['verified_by'] ?? 'N/A',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),

                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Checked by:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              order['checked_by'] ?? 'N/A',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),

                                        // Shipping Charge
                                        // Row(
                                        //   mainAxisAlignment:
                                        //       MainAxisAlignment.spaceBetween,
                                        //   children: [
                                        //     Text(
                                        //       'Shipping Charge:',
                                        //       style: TextStyle(
                                        //         fontWeight: FontWeight.bold,
                                        //         fontSize: 14,
                                        //       ),
                                        //     ),
                                        //     Text(
                                        //       order['shipping_charge'] ?? 'N/A',
                                        //       style: TextStyle(fontSize: 14),
                                        //     ),
                                        //   ],
                                        // ),
                                        // SizedBox(height: 6),

                                        // // Parcel Service
                                        // Row(
                                        //   mainAxisAlignment:
                                        //       MainAxisAlignment.spaceBetween,
                                        //   children: [
                                        //     Text(
                                        //       'Parcel Service:',
                                        //       style: TextStyle(
                                        //         fontWeight: FontWeight.bold,
                                        //         fontSize: 14,
                                        //       ),
                                        //     ),
                                        //     Text(
                                        //       order['parcel_service'] ?? 'N/A',
                                        //       style: TextStyle(fontSize: 14),
                                        //     ),
                                        //   ],
                                        // ),
                                        SizedBox(height: 4),

                                        // Tracking ID
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Tracking ID:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              order['tracking_id']
                                                      ?.toString() ??
                                                  'N/A',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),

                                        // Status
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
                                                getStatusDisplayName(order['status']),
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 4),

                                        // Shipped Date
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Shipped Date:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              order['shipped_date'] ?? 'N/A',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ],
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
}
