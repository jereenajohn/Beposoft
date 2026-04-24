import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerList extends StatefulWidget {
  const CustomerList({super.key});

  @override
  State<CustomerList> createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList> {
  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> customer = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getCustomer();
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> downloadDataAsExcel() async {
    if (await Permission.storage.request().isGranted) {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['CustomerData'];
      
      // Add headers
      sheetObject.appendRow(['ID', 'Name', 'Created At']);
      
      // Add customer data rows
      for (var customer in filteredProducts) {
        sheetObject.appendRow([
          customer['id'],
          customer['name'],
          customer['created_at'],
        ]);
      }
      
      // Encode and save Excel file
      var bytes = excel.encode()!;
      Directory? directory;
      
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        final path = "${directory!.path}/Download/CustomerData.xlsx";
        final file = File(path);
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Excel file downloaded to $path")),
        );
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
        final path = "${directory.path}/CustomerData.xlsx";
        final file = File(path);
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Excel file saved to $path")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Storage permission denied")),
      );
    }
  }

  Future<void> getCustomer() async {
    try {
      final token = await getTokenFromPrefs();
      var response = await http.get(
        Uri.parse('https://api.yourwebsite.com/api/customers/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];
        List<Map<String, dynamic>> managerlist = [];

        for (var productData in productsData) {
          managerlist.add({
            'id': productData['id'],
            'name': productData['name'],
            'created_at': productData['created_at']
          });
        }

        setState(() {
          customer = managerlist;
          filteredProducts = List.from(customer);
        });
      }
    } catch (error) {
      
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredProducts = List.from(customer);
      } else {
        filteredProducts = customer
            .where((product) =>
                product['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Customer List",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: downloadDataAsExcel,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search customers...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(
                    color: Colors.blue,
                    width: 2.0,
                  ),
                ),
              ),
              onChanged: _filterProducts,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final customerData = filteredProducts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customerData['name'] ?? '',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Created on: ${customerData['created_at']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: Colors.blue),
                          onSelected: (value) {
                            if (value == 'View') {
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) => ViewCustomer(customerId: customerData['id']),
                              //   ),
                              // );
                            } else if (value == 'Add Address') {
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) => AddAddress(customerId: customerData['id']),
                              //   ),
                              // );
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem<String>(
                              value: 'View',
                              child: Text('View'),
                            ),
                            PopupMenuItem<String>(
                              value: 'Add Address',
                              child: Text('Add Address'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
