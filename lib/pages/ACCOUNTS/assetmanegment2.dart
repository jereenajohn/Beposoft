import 'dart:convert';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AssetManegment2 extends StatefulWidget {
  const AssetManegment2({super.key});

  @override
  State<AssetManegment2> createState() => _AssetManegment2State();
}

class _AssetManegment2State extends State<AssetManegment2> {
  List<Map<String, dynamic>> assetsData = [];
  List<String> categories = [];
  String? selectedCategory;
  List<Map<String, dynamic>> selectedCategoryProducts = [];
  int totalStock = 0;
  double totalPrice = 0.0;

  List<Map<String, dynamic>> liabilitiesData = [];
  double totalLiabilities = 0.0;
  bool showAssets = true; // Toggle state (true = Assets, false = Liabilities)

  @override
  void initState() {
    super.initState();
    getAssets();
    getLiability();
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> getAssets() async {
    try {
      final token = await getTokenFromPrefs();
      var response = await http.get(
        Uri.parse('$api/apis/get/asset/report/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        List<Map<String, dynamic>> fetchedAssets =
            List<Map<String, dynamic>>.from(parsed['assets']);

        List<String> fetchedCategories =
            fetchedAssets.map((e) => e['category'] as String).toList();

        setState(() {
          assetsData = fetchedAssets;
          categories = fetchedCategories;
          if (categories.isNotEmpty) {
            selectedCategory = categories.first;
            updateSelectedCategoryProducts(selectedCategory!);
          }
        });
      }
    } catch (error) {
      ;
    }
  }

  Future<void> getLiability() async {
    try {
      final token = await getTokenFromPrefs();
      final response = await http.get(
        Uri.parse('$api/apis/liability/get/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var fetchedLiabilities = parsed['liabilities'];

        setState(() {
          liabilitiesData = fetchedLiabilities
              .map<Map<String, dynamic>>((liability) => {
                    'emi_name': liability['emi_name'],
                    'pending_amount': liability['pending_amount'] ?? 0.0,
                  })
              .toList();

          // Calculate total liabilities
          totalLiabilities = liabilitiesData.fold<double>(
            0.0,
            (sum, item) => sum + (item['pending_amount'] ?? 0.0),
          );
        });
      }
    } catch (error) {
      ;
    }
  }

  void updateSelectedCategoryProducts(String category) {
    setState(() {
      selectedCategoryProducts = assetsData
          .firstWhere((element) => element['category'] == category)['products']
          .map<Map<String, dynamic>>((product) => {
                'name': product['name'],
                'stock': product['stock'] ?? product['quantity'] ?? 0,
                'price': product['landing_cost'] ?? product['amount'] ?? 0.0,
              })
          .toList();

      totalStock = selectedCategoryProducts.fold<int>(
          0, (sum, item) => sum + (item['stock'] as int));
      totalPrice = selectedCategoryProducts.fold<double>(
          0.0,
          (sum, item) =>
              sum +
              ((item['stock'] as int) *
                  (double.tryParse(item['price'].toString()) ?? 0.0)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Asset Management")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              // Summary Card
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Total Assets",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                          Text("₹${totalPrice.toStringAsFixed(2)}",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Total Liabilities",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                          Text("₹${totalLiabilities.toStringAsFixed(2)}",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Toggle Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => showAssets = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: showAssets ? Colors.blue : Colors.grey,
                    ),
                    child: const Text(
                      "Assets",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => setState(() => showAssets = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !showAssets ? Colors.blue : Colors.grey,
                    ),
                    child: const Text(
                      "Liabilities",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (showAssets) ...[
                // Dropdown for categories
                DropdownButton<String>(
                  value: selectedCategory,
                  items: categories
                      .map((category) => DropdownMenuItem(
                          value: category, child: Text(category)))
                      .toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedCategory = newValue;
                      updateSelectedCategoryProducts(newValue!);
                    });
                  },
                  isExpanded: true,
                ),
                const SizedBox(height: 10),

                // Assets Table
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.blue.shade100),
                    border:
                        TableBorder.all(color: Colors.grey.shade300, width: 1),
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Stock')),
                      DataColumn(label: Text('Price')),
                    ],
                    rows: selectedCategoryProducts
                        .map(
                          (product) => DataRow(
                            cells: [
                              DataCell(Text(product['name'])),
                              DataCell(Text(product['stock'].toString())),
                              DataCell(Text(
                                  '₹${product['price'].toStringAsFixed(2)}')),
                            ],
                          ),
                        )
                        .toList()
                      ..add(
                        DataRow(
                          color: MaterialStateColor.resolveWith(
                              (states) => Colors.blue.shade50),
                          cells: [
                            DataCell(Text('Total',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                            DataCell(Text(totalStock.toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                            DataCell(Text('₹${totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green))),
                          ],
                        ),
                      ),
                  ),
                ),
              ],
              if (!showAssets) ...[
                // Liabilities Table
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.blue.shade100),
                    border:
                        TableBorder.all(color: Colors.grey.shade300, width: 1),
                    columns: const [
                      DataColumn(label: Text('EMI Name')),
                      DataColumn(label: Text('Pending Amount')),
                    ],
                    rows: liabilitiesData
                        .map(
                          (liability) => DataRow(
                            cells: [
                              DataCell(Text(liability['emi_name'])),
                              DataCell(Text(
                                  '₹${liability['pending_amount'].toStringAsFixed(2)}')),
                            ],
                          ),
                        )
                        .toList()
                      ..add(
                        DataRow(
                          color: MaterialStateColor.resolveWith(
                              (states) => Colors.blue.shade50),
                          cells: [
                            DataCell(Text('Total',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                            DataCell(Text(
                                '₹${totalLiabilities.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red))),
                          ],
                        ),
                      ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
