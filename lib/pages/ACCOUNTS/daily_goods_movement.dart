import 'dart:convert';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dgm.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/profilepage.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class daily_goods_movement extends StatefulWidget {
  @override
  _daily_goods_movementState createState() => _daily_goods_movementState();
}

class _daily_goods_movementState extends State<daily_goods_movement> {
  List<Map<String, dynamic>> goods = [];
  List<Map<String, dynamic>> filteredOrders = [];
  List<Map<String, dynamic>> overallTopProducts = [];
  bool showAllTopProducts = false;

  bool isLoading = true;
  String? errorMessage;

  DateTime? selectedDate; // For single date filter
  DateTime? startDate; // For date range filter
  DateTime? endDate; // For date range filter
// //dateselection
//    DateTime selectedDate = DateTime.now();

//   Future<void> _selectDate(BuildContext context) async {
//
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//
//       });
//     }
//   }

  Future<void> getgoodsdetails({DateTime? fromDate, DateTime? toDate}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = "Token not found. Please login again.";
        });
        return;
      }

      String url = '$api/api/warehouse/box/detail/';

      if (fromDate != null && toDate != null) {
        final fromDateText = DateFormat('yyyy-MM-dd').format(fromDate);
        final toDateText = DateFormat('yyyy-MM-dd').format(toDate);

        url = '$url?from_date=$fromDateText&to_date=$toDateText';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final productsData = jsonDecode(response.body);

        if (productsData is! List) {
          setState(() {
            goods = [];
            filteredOrders = [];
            overallTopProducts = [];
            isLoading = false;
            errorMessage = "Invalid API response format.";
          });
          return;
        }

        final List<Map<String, dynamic>> goodsList = [];
        final List<Map<String, dynamic>> topProductsList = [];

        for (var productData in productsData) {
          if (productData is! Map<String, dynamic>) {
            continue;
          }

          /*
          First object example:
          {
            "from_date": null,
            "to_date": null,
            "top_5_products": [...]
          }

          This is overall top products.
          Show this below date filter.
        */
          if (productData['shipped_date'] == null) {
            final topProducts = productData['top_5_products'];

            if (topProducts is List) {
              for (var product in topProducts) {
                if (product is Map<String, dynamic>) {
                  topProductsList.add({
                    'product_id': product['product_id'],
                    'product_name': product['product_name'] ?? '',
                    'display_name': product['display_name'] ??
                        product['product_name'] ??
                        '',
                    'total_quantity': product['total_quantity'] ?? 0,
                    'total_amount': product['total_amount'] ?? 0,
                  });
                }
              }
            }

            continue;
          }

          final totalWeightRaw = productData['total_weight'] ?? 0;
          final totalWeight = double.tryParse(totalWeightRaw.toString()) ?? 0.0;

          final List<Map<String, dynamic>> dateWiseTopProducts = [];

          final topProducts = productData['top_5_products'];
          if (topProducts is List) {
            for (var product in topProducts) {
              if (product is Map<String, dynamic>) {
                dateWiseTopProducts.add({
                  'product_id': product['product_id'],
                  'product_name': product['product_name'] ?? '',
                  'variant_id': product['variant_id'],
                  'variant_name': product['variant_name'],
                  'display_name':
                      product['display_name'] ?? product['product_name'] ?? '',
                  'total_quantity': product['total_quantity'] ?? 0,
                  'total_amount': product['total_amount'] ?? 0,
                });
              }
            }
          }

          goodsList.add({
            'shipped_date': productData['shipped_date'] ?? '',
            'total_weight': (totalWeight / 1000).toStringAsFixed(2),
            'total_boxes': productData['total_boxes'] ?? 0,
            'total_volume_weight': productData['total_volume_weight'] ?? 0,
            'total_shipping_charge': productData['total_shipping_charge'] ?? 0,
            'total_actual_weight': productData['total_actual_weight'] ?? 0,
            'total_parcel_amount': productData['total_parcel_amount'] ?? 0,
            'total_invoice_count': productData['total_invoice_count'] ?? 0,
            'total_order_amount': productData['total_order_amount'] ?? 0,

            // Important: this is date-wise top 5 products.
            'top_5_products': dateWiseTopProducts,
          });
        }

        setState(() {
          goods = goodsList;
          filteredOrders = goodsList;
          overallTopProducts = topProductsList;
          showAllTopProducts = false;
          isLoading = false;
        });
      } else {
        setState(() {
          goods = [];
          filteredOrders = [];
          overallTopProducts = [];
          isLoading = false;
          errorMessage =
              "Failed to fetch data. Status code: ${response.statusCode}";
        });
      }
    } catch (error) {
      setState(() {
        goods = [];
        filteredOrders = [];
        overallTopProducts = [];
        isLoading = false;
        errorMessage = "Something went wrong: $error";
      });
    }
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

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

  Future<void> _clearDateFilter() async {
    setState(() {
      startDate = null;
      endDate = null;
    });

    await getgoodsdetails();
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('token');

    // Show a snackbar with the logout success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logout successfully'),
        duration: Duration(
            seconds: 2), // Optional: Set how long the snackbar will be visible
      ),
    );

    // Navigate to the HomePage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login()),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });

      await getgoodsdetails(
        fromDate: picked.start,
        toDate: picked.end,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getgoodsdetails();
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

  Widget _buildOverallTopProducts() {
    if (overallTopProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    String title = "Top 5 Products";
    if (startDate != null && endDate != null) {
      title =
          "Top 5 Products (${DateFormat('dd-MM-yyyy').format(startDate!)} to ${DateFormat('dd-MM-yyyy').format(endDate!)})";
    }

    final List<Map<String, dynamic>> visibleProducts = showAllTopProducts
        ? overallTopProducts
        : overallTopProducts.take(2).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 12, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade400,
                width: 0.8,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 36,
                    dataRowHeight: 34,
                    headingRowColor: MaterialStateColor.resolveWith(
                      (states) => Colors.blue,
                    ),
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        width: 0.5,
                        color: Colors.grey.shade400,
                      ),
                      verticalInside: BorderSide(
                        width: 0.5,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    columnSpacing: 10,
                    columns: const [
                      DataColumn(
                        label: SizedBox(
                          width: 55,
                          child: Text(
                            "Sl No",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 230,
                          child: Text(
                            "Product",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 70,
                          child: Text(
                            "Qty",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 100,
                          child: Text(
                            "Amount",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                    rows: List<DataRow>.generate(
                      visibleProducts.length,
                      (index) {
                        final product = visibleProducts[index];

                        final String productName =
                            product['display_name']?.toString().isNotEmpty ==
                                    true
                                ? product['display_name'].toString()
                                : product['product_name']?.toString() ?? '-';

                        final String quantity =
                            product['total_quantity']?.toString() ?? '0';

                        final double amount = double.tryParse(
                              product['total_amount']?.toString() ?? '0',
                            ) ??
                            0.0;

                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 55,
                                child: Text(
                                  "${index + 1}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 230,
                                child: Text(
                                  productName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 70,
                                child: Text(
                                  quantity,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 100,
                                child: Text(
                                  amount.toStringAsFixed(2),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                if (overallTopProducts.length > 2)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.shade400,
                          width: 0.5,
                        ),
                      ),
                    ),
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          showAllTopProducts = !showAllTopProducts;
                        });
                      },
                      icon: Icon(
                        showAllTopProducts
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: Colors.blue,
                      ),
                      label: Text(
                        showAllTopProducts ? "See Less" : "See More",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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
        appBar: AppBar(
          title: Text(
            "Daily Goods Movement",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
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
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => EditProfileScreen()));
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Padding(
            //   padding: const EdgeInsets.all(10),
            //   child: Container(
            //           height: 46,
            //           decoration: BoxDecoration(
            //             border: Border.all(
            //   color: Colors.blue,
            //   width: 1.0,
            //             ),
            //             borderRadius: BorderRadius.circular(8.0),
            //           ),
            //           child: Row(
            //             children: [
            //   SizedBox(width: 25,),
            //   Text(
            //     '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
            //     style: TextStyle(fontSize:12,color:Color.fromARGB(255, 116, 116, 116)),
            //   ),
            //   SizedBox(width: 162,),
            //   GestureDetector(
            //     onTap: () {
            //     _selectDate(context);
            //
            //     },
            //     child: Container(
            //       padding: const EdgeInsets.only(left: 55),
            //       child: Icon(Icons.date_range)),
            //   ),
            //             ],
            //           ),
            //         ),
            // ),

            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.date_range,
                            size: 18,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              startDate != null && endDate != null
                                  ? "${DateFormat('dd-MM-yyyy').format(startDate!)} to ${DateFormat('dd-MM-yyyy').format(endDate!)}"
                                  : "All dates",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _selectDateRange(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    child: const Text(
                      'Filter',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _clearDateFilter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            _buildOverallTopProducts(),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      : filteredOrders.isEmpty
                          ? const Center(
                              child: Text(
                                "No goods movement data found",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(5.0),
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) {
                                final item = filteredOrders[index];

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Dgm(
                                          shipped_date: item['shipped_date'],
                                          topFiveProducts:
                                              List<Map<String, dynamic>>.from(
                                            item['top_5_products'] ?? [],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 15),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.shade100,
                                          Colors.blue.shade300,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today,
                                                color: Colors.blue.shade700),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "Shipped Date: ${item['shipped_date']}",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color.fromARGB(
                                                      255, 32, 0, 0),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Icon(Icons.add_box,
                                                color: Colors.blue.shade700),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "Total Boxes: ${item['total_boxes']}",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.blue.shade800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Icon(Icons.fitness_center,
                                                color: Colors.blue.shade700),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "Total A/W: ${item['total_weight']} kg",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.blue.shade800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Icon(Icons.fitness_center_sharp,
                                                color: Colors.blue.shade700),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "Volume Weight: ${item['total_volume_weight']} kg",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.blue.shade800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Icon(Icons.attach_money,
                                                color: Colors.blue.shade700),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "Shipping Charge: ₹${item['total_shipping_charge']}",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.blue.shade800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            )
          ],
        ),
      ),
    );
  }
}
