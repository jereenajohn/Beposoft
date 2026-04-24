import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/view_customer_transfer.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:intl/intl.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/update_bank.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:beposoft/pages/api.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

class updatecustomertransfer extends StatefulWidget {
  var id;
  updatecustomertransfer({super.key, required this.id});

  @override
  State<updatecustomertransfer> createState() => _updatecustomertransferState();
}

class _updatecustomertransferState extends State<updatecustomertransfer> {
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

  TextEditingController uname = TextEditingController();
  TextEditingController amount = TextEditingController();
  TextEditingController transactionid = TextEditingController();
  TextEditingController Remark = TextEditingController();
  List<Map<String, dynamic>> bank = [];
  List<Map<String, dynamic>> orders = [];
    List<Uint8List> selectedImageslist = [];

  DateTime selectedDate = DateTime.now();
  String? selectedInvoiceId; // Variable to store the selected invoice ID
  String? selectedBankId; // Variable to store the selected bank ID
  var respo;
// Add this variable to your _add_receiptState class:
String? selectedReceiptType;
final List<String> receiptTypes = ['Order Refund', 'Advance Refund'];
  Future<String?> gettoken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString('token');
  }

  @override
  void initState() {
    super.initState();
   gettransfer();
 getcustomer();
    // getNameFromJWT(); // Fetch the name from JWT
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  List<Map<String, dynamic>> customer = [];
String? selectedCustomerId;
String? slectedCustomerid2;
  Future<void> getcustomer() async {
  try {
    final dep = await getdepFromPrefs();
    final token = await getTokenFromPrefs();

    final jwt = JWT.decode(token!);
    var name = jwt.payload['name'];
    

    var response = await http.get(
      Uri.parse('$api/api/customers/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    ;

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      var productsData = parsed['data']; // Directly accessing 'data' since no pagination

      List<Map<String, dynamic>> newCustomers = [];

      for (var productData in productsData) {
        newCustomers.add({
          'id': productData['id'],
          'name': productData['name'],
          'created_at': productData['created_at'],
        });
      }

      // Update UI
      setState(() {
        customer = newCustomers;
        uname.text=name;
        
      });
    } else {
      throw Exception("Failed to load customer data");
    }
  } catch (error) {
    ;
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
Future<bool> deleteTransferImage(int imageId) async {
  try {
    final token = await getTokenFromPrefs();

    final response = await http.delete(
      Uri.parse('$api/api/advance/transfer/image/$imageId/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );


    return response.statusCode == 200 || response.statusCode == 204;
  } catch (e) {
    return false;
  }
}

Future<void> Addrefundlog(BuildContext scaffoldContext, dynamic respo) async {
  final token = await getTokenFromPrefs();

  try {
   

    // 3️⃣ Safe POST request
    final response = await http.post(
      Uri.parse('$api/api/datalog/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'before_data': {
          "status": "Refund added"
        },
        'after_data': {
          'refund_no': respo['refund_no'],
          'customer_name': respo['customer_name'],
          'amount': respo['amount'],
          'created_by': respo['created_name'],
          'date': respo['date'],
          'invoice': respo['invoice'],
        },
        'order': "",
      }),
    );


    if (response.statusCode == 201) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Note log added successfully.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Log creation failed.'),
        ),
      );
    }
  } catch (e) {

    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text('Unexpected error while adding log'),
      ),
    );
  }
}
List<Map<String, dynamic>> existingImages = [];

Future<void> gettransfer() async {
  final token = await getTokenFromPrefs();

  try {
    final response = await http.get(
      Uri.parse('$api/api/advance/transfer/update/${widget.id}/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );


    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      final data = parsed['data']; // ✅ single object

      setState(() {
        // 🔹 Amount & Remark
        amount.text = data['amount']?.toString() ?? '';
        Remark.text = data['note'] ?? '';

        // 🔹 Customers (VERY IMPORTANT)
        selectedCustomerId = data['send_from']?.toString();
        slectedCustomerid2 = data['send_to']?.toString();

        // 🔹 Date
        if (data['date'] != null) {
          selectedDate = DateTime.parse(data['date']);
        }

        existingImages =
    List<Map<String, dynamic>>.from(data['amount_transfer_images'] ?? []);


        // 🔹 Name (logged-in user)
        final jwt = JWT.decode(token!);
        uname.text = jwt.payload['name'];
      });

    } else {
    }
  } catch (e) {
  }
}

Future<void> Addtransfer(BuildContext scaffoldContext) async {
  try {
    final token = await getTokenFromPrefs();
    final jwt = JWT.decode(token!);
    var name = jwt.payload['name'];

    String formattedDate =
        DateFormat('yyyy-MM-dd').format(selectedDate);

    final uri = Uri.parse('$api/api/advance/transfer/update/${widget.id}/');
    final request = http.MultipartRequest('PUT', uri);

    // ✅ Headers (NO Content-Type)
    request.headers['Authorization'] = 'Bearer $token';

    // ✅ Normal fields
    request.fields['send_from'] = selectedCustomerId ?? '';
    request.fields['send_to'] = slectedCustomerid2 ?? '';
    request.fields['date'] = formattedDate;
    request.fields['created_by'] = name;
    request.fields['note'] = Remark.text;
    request.fields['amount'] = amount.text;

    // ✅ Images (VERY IMPORTANT)
    for (int i = 0; i < selectedImageslist.length; i++) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'images', // 🔴 must match backend field name
          selectedImageslist[i],
          filename: 'transfer_$i.jpg',
        ),
      );
    }

    final streamedResponse = await request.send();
    final response =
        await http.Response.fromStream(streamedResponse);


    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      respo = data['data'];

      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Transfer added successfully'),
        ),
      );

      Addrefundlog(scaffoldContext, respo);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => customertransferList()),
      );
    } else {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed: ${response.body}'),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text('Unexpected error while submitting'),
      ),
    );
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

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }
  Future<String?> getusername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  // void getNameFromJWT() async {
  //   final token = await getTokenFromPrefs();
  //   if (token != null) {
  //     final jwt = JWT.decode(token);
  //     setState(() {
  //       name = jwt.payload['name']; // Extract and set the name
  //       ;
  //     });
  //   }
  // }
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
    return WillPopScope(
        onWillPop: () async {
        // Prevent the swipe-back gesture (and back button)
        _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: Color.fromARGB(242, 255, 255, 255),
        appBar: AppBar(
          title: Text(
            "Customer Transfer",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back), // Custom back arrow
            onPressed: () async {
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
              padding: const EdgeInsets.only(bottom:55),
              child: Container(
                        child: Column(
              children: [
                SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 10, left: 10),
                  child: Container(
                    width: 600,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 34, 165, 246),
                      border: Border.all(color: Color.fromARGB(255, 202, 202, 202)),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Customer Transfer",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        SizedBox(
                          height: 13,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 25, left: 15, right: 15),
                  child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        border:
                            Border.all(color: Color.fromARGB(255, 202, 202, 202)),
                      ),
                      width: 700,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 10,
                            ),
            
                            Text(
                                "From Customer",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 5),
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: selectedCustomerId,
                                    hint: Text(
                                      'From Customer',
                                      style: TextStyle(fontSize: 12.0),
                                    ),
              
                items: customer.map((cust) {
                                      return DropdownMenuItem<String>(
                                        value: cust['id'].toString(),
                                        child: Text(
                                          cust['name'],
                                          style: TextStyle(fontSize: 12.0),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedCustomerId = value;
                                      });
                                    },
                                    underline: SizedBox(),
                                  ),
                                ),
                              ),
                              Text(
                                "To Customer",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 5),
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: slectedCustomerid2,
                                    hint: Text(
                                      'To Customer',
                                      style: TextStyle(fontSize: 12.0),
                                    ),
              
                items: customer.map((cust) {
                                      return DropdownMenuItem<String>(
                                        value: cust['id'].toString(),
                                        child: Text(
                                          cust['name'],
                                          style: TextStyle(fontSize: 12.0),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        slectedCustomerid2 = value;
                                      });
                                    },
                                    underline: SizedBox(),
                                  ),
                                ),
                              ),
                            SizedBox(
                              height: 5,
                            ),
                            Text(
                              "Amount",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Container(
                                child: TextField(
                                  controller: amount,
                                  decoration: InputDecoration(
                                    labelText: 'Amount',
                                    labelStyle: TextStyle(
                                      fontSize: 12.0, // Set your desired font size
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              "Date",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                           // ...existing code...
Padding(
  padding: const EdgeInsets.only(right: 10),
  child: GestureDetector(
    onTap: () async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (pickedDate != null) {
        setState(() {
          selectedDate = pickedDate;
        });
      }
    },
    child: AbsorbPointer(
      child: TextField(
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Date',
          labelStyle: TextStyle(fontSize: 12.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 8.0),
        ),
        controller: TextEditingController(
          text: DateFormat('yyyy-MM-dd').format(selectedDate),
        ),
      ),
    ),
  ),
),

                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              "Name",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Container(
                                child: TextField(
                                  controller: TextEditingController(
                                      text: uname.text), // Display the name extracted from JWT
                                  readOnly: true, // Make the field non-editable
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    labelStyle: TextStyle(
                                      fontSize: 12.0, // Set your desired font size
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                              ),
                            ),  SizedBox(height: 10),
                            Text(
                              "Remark",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Padding(
  padding: const EdgeInsets.only(right: 10),
  child: TextField(
    controller: Remark,
    maxLines: 3,        // expands up to 3 lines only
    keyboardType: TextInputType.multiline,
    decoration: InputDecoration(
      labelText: 'Remark',
      labelStyle: const TextStyle(
        fontSize: 12.0,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 10.0,
      ),
    ),
  ),
),
                            SizedBox(
                              height: 10,
                            ),
                            if (existingImages.isNotEmpty) ...[
  const Text(
    "Existing Attachments",
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
  ),
  const SizedBox(height: 6),

  GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: existingImages.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
    ),
    itemBuilder: (context, index) {
      final imgUrl = '$api${existingImages[index]['image']}';

      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imgUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // ❌ DELETE ICON
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () async {
  final imageId = existingImages[index]['id'];

  final success = await deleteTransferImage(imageId);

  if (success) {
    setState(() {
      existingImages.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Image deleted successfully'),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text('Failed to delete image'),
      ),
    );
  }
},

              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    },
  ),

  const SizedBox(height: 10),
]

,

                            Text(
  "Upload Images",
  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
),
const SizedBox(height: 5),

GestureDetector(
  onTap: selectMultipleImages,
  child: Padding(
    padding: const EdgeInsets.only( right: 10.0),
    child: Container(
       width: double.infinity, 
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade100,
      ),
      child: selectedImageslist.isEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 32, color: Colors.grey),
                SizedBox(height: 6),
                Text(
                  "Tap to select images",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            )
          : GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: selectedImageslist.length,
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 6,
    mainAxisSpacing: 6,
  ),
  itemBuilder: (context, index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            selectedImageslist[index],
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        // ❌ DELETE ICON
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedImageslist.removeAt(index);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  },
),

    ),
  ),
),

const SizedBox(height: 10),



                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                  ),
                                  SizedBox(
                                    width: 270,
                                    child: ElevatedButton(
                                      onPressed: () {
                                       Addtransfer(context);
                                      },
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                          Color.fromARGB(255, 64, 176, 251),
                                        ),
                                        shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                10), // Set your desired border radius
                                          ),
                                        ),
                                        fixedSize: MaterialStateProperty.all<Size>(
                                          Size(95,
                                              15), // Set your desired width and heigh
                                        ),
                                      ),
                                      child: Text("Submit",
                                          style: TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ]),
                            SizedBox(
                              height: 20,
                            )
                          ],
                        ),
                      )),
                ),
              ],
                        ),
                      ),
            )),
      ),
    );
  }
}
