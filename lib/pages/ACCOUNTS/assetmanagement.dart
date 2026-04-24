import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/update_department.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:beposoft/pages/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AssetManegment extends StatefulWidget {
  const AssetManegment({super.key});

  @override
  State<AssetManegment> createState() => _AssetManegmentState();
}

class _AssetManegmentState extends State<AssetManegment> {
  @override
  void initState() {
    super.initState();
    getAssets();
    getliability();
  }

  List<Map<String, dynamic>> expensedata = [];
  List<Map<String, dynamic>> assets = [];
  List<Map<String, dynamic>> filteredData = [];
  double totalAmount = 0;
  int totalStock = 0;
  double totalLiabilities = 0;

  TextEditingController department = TextEditingController();

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

 Future<void> getAssets() async {
  try {
    final token = await gettokenFromPrefs();

    var response = await http.get(
      Uri.parse('$api/apis/get/asset/report/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      List<dynamic> categoriesData = parsed['assets'];
      List<Map<String, dynamic>> categoriesSummary = [];

      for (var categoryData in categoriesData) {
        String categoryName = categoryData['category'];
        List<dynamic> products = categoryData['products'];


        int categoryTotalStock = 0;
        double categoryTotalPrice = 0.0;

        List<Map<String, dynamic>> productList = [];

        for (var product in products) {
          int stock = product['stock'] ?? product['quantity'] ?? 0;
          double price = 0.0;

          if (product['landing_cost'] != null) {
            price = double.tryParse(product['landing_cost'].toString()) ?? 0.0;
          } else if (product['amount'] != null) {
            price = double.tryParse(product['amount'].toString()) ?? 0.0;
          }


          categoryTotalStock += stock;
          categoryTotalPrice += stock * price;

          productList.add({
            'name': product['name'],
            'stock': stock ?? 1,
            'price': price,
          });
        }

        categoriesSummary.add({
          'category': categoryName,
          'totalStock': categoryTotalStock,
          'totalPrice': categoryTotalPrice,
          'products': productList,
          'isExpanded': false,
        });
      }

      setState(() {
        assets = categoriesSummary;

      });
    }
  } catch (error) {
    ;
  }
}


  Future<void> getliability() async {
    try {
      final token = await gettokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/apis/liability/get/'), // Ensure the endpoint is correct
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    ;

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var liabilitiesData = parsed['liabilities'];

        List<Map<String, dynamic>> liabilitiesList = [];

        for (var liability in liabilitiesData) {
          liabilitiesList.add({
            'emi_name': liability['emi_name'],
            'pending_amount': liability['pending_amount'],
          });
        }

        setState(() {
          expensedata = liabilitiesList;
          totalLiabilities = expensedata.fold<double>(
            0.0,
            (sum, item) => sum + (item['pending_amount'] ?? 0.0),
          );
        });
      }
    } catch (error) {
      ;
    }
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }
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
    double totalLiabilities = expensedata.fold<double>(
      0.0,
      (sum, item) => sum + (item['pending_amount'] ?? 0.0),
    );

    return Scaffold(
      backgroundColor: Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(
        title: Text(
          "Asset Management",
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

    else if(dep=="warehouse" ){
       Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WarehouseDashboard()), // Replace AnotherPage with your target page
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
      body: assets.isEmpty && expensedata.isEmpty
          ? Center(
              child: Text(
                'No assets or liabilities available',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Card(
      color: const Color.fromARGB(255, 247, 253, 202),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.all(10),
      child: Padding(
    padding: const EdgeInsets.all(12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Assets: ₹${assets.fold<double>(0.0, (sum, item) => sum + item['totalPrice']).toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Liabilities: ₹${totalLiabilities.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Capital: ₹${(assets.fold<double>(0.0, (sum, item) => sum + item['totalPrice']) - totalLiabilities).toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 54, 124, 244)),
            ),
          ],
        ),
      ],
    ),
      ),
    ),
    
                Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
    if (assets.isNotEmpty)
      Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Asset Summary',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 10),
              ...assets.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                bool isExpanded = category['isExpanded'] ?? false;
    
                return Column(
                  children: [
                    ListTile(
                      tileColor:
                          index % 2 == 0 ? Colors.grey.shade100 : Colors.white,
                      title: Text(category['category'],
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: Row(
                        children: [
                          if(category['totalStock'] != 0)
                          Text('Stock: ${category['totalStock']}',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          SizedBox(width: 20),
                          Text('₹${category['totalPrice'].toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, color: Colors.green)),
                        ],
                      ),
                      trailing: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more),
                      onTap: () {
                        setState(() {
                          category['isExpanded'] = !isExpanded;
                        });
                      },
                    ),
                   if (isExpanded)
      Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Column(
      children: (category['products'] as List<dynamic>? ?? []).map<Widget>((product) {
        final stock = product['stock'] ?? 0;
        final price = product['price'] ?? 0.0; // <-- correctly referencing 'price'
       return ListTile(
          dense: true,
          title: Text(product['name'], style: TextStyle(fontSize: 14)),
          subtitle: stock != 0 ? Text('Stock: $stock') : null, // Display stock only if it's not 0
          trailing: Text('₹${price.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey.shade700)),
        );
      }).toList(),
    ),
      ),
    
    
                  ],
                );
              }).toList(),
              Divider(),
              ListTile(
                tileColor: Colors.blue.shade50,
                title: Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Row(
                  children: [
                    Text(
                      'Stock: ${assets.fold<int>(0, (sum, item) => sum + (item['totalStock'] as num).toInt())}',
    
                      style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 20),
                    Text(
                      '₹${assets.fold<double>(0.0, (sum, item) => sum + item['totalPrice']).toStringAsFixed(2)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ],
    ),
    
                  if (expensedata.isNotEmpty) ...[
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: EdgeInsets.all(10),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Liabilities Summary',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue),
                            ),
                            const SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 20,
                                headingRowHeight: 40,
                                dataRowHeight: 40,
                                headingRowColor: MaterialStateColor.resolveWith(
                                    (states) => Colors.blue.shade100),
                                border: TableBorder.all(
                                    color: Colors.grey.shade300, width: 1),
                                columns: [
                                  DataColumn(
                                      label: Text('EMI Name',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue))),
                                  DataColumn(
                                      label: Text('Pending Amount',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue))),
                                ],
                                rows: [
                                  ...expensedata.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final liability = entry.value;
    
                                    return DataRow(
                                      color: MaterialStateColor.resolveWith((states) =>
                                          index % 2 == 0
                                              ? Colors.grey.shade100
                                              : Colors.white),
                                      cells: [
                                        DataCell(Text(liability['emi_name'],
                                            style: TextStyle(fontSize: 14))),
                                        DataCell(Text('₹${liability['pending_amount'].toStringAsFixed(2)}',
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: liability['pending_amount'] < 0
                                                    ? Colors.red
                                                    : Colors.green))),
                                      ],
                                    );
                                  }).toList(),
                                  DataRow(
                                    color: MaterialStateColor.resolveWith(
                                        (states) => Colors.blue.shade50),
                                    cells: [
                                      DataCell(Text('Total',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                      DataCell(Text(
                                          '₹${totalLiabilities.toStringAsFixed(2)}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
