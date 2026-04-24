import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/Today_shipped_orders.dart';
import 'package:beposoft/pages/ACCOUNTS/add_EMI.dart';
import 'package:beposoft/pages/ACCOUNTS/add_category.dart';
import 'package:beposoft/pages/ACCOUNTS/add_purpose_of_payment.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_warehouse.dart';
import 'package:beposoft/pages/ACCOUNTS/assetmanagement.dart';
import 'package:beposoft/pages/ACCOUNTS/assetmanegment2.dart';
import 'package:beposoft/pages/ACCOUNTS/bulk_customer_upload.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
// import 'package:beposoft/pages/ACCOUNTS/call_log.dart';
import 'package:beposoft/pages/ACCOUNTS/graph.dart';
import 'package:beposoft/pages/ACCOUNTS/grv_list.dart';
import 'package:beposoft/pages/ACCOUNTS/order_list.dart';
import 'package:beposoft/pages/ACCOUNTS/performa_invoice_list.dart';
import 'package:beposoft/pages/ACCOUNTS/todays_orders_list.dart';
import 'package:beposoft/pages/ACCOUNTS/uploadbulkorders.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_single_family_data.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/MARKETING/marketing_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_product_approval.dart';
import 'package:intl/intl.dart';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_family.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ACCOUNTS/profilepage.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ceo_family_summary extends StatefulWidget {
  @override
  State<ceo_family_summary> createState() => _ceo_family_summaryState();
}

class _ceo_family_summaryState extends State<ceo_family_summary> {
  List<String> statusOptions = ["pending", "approved", "rejected"];
  List<Map<String, dynamic>> grvlist = [];
  List<Map<String, dynamic>> proforma = [];
  List<Map<String, dynamic>> salesReportList = [];
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  List<Map<String, dynamic>> shippedOrders = [];
  List<Map<String, dynamic>> Finance = [];
  List<dynamic> internalTransfers = [];
  double todayCredit = 0.0;
  double todayDebit = 0.0;
  double openingBalance = 0.0;
  double closingBalance = 0.0;

  String? username = '';
  @override
  void initState() {
    super.initState();
    initdata();
    // fetchOrderData();

    //   fetchInternalTransfersData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAppUpdate(context);
    });
  }

  var department;
  void initdata() async {
    department = await getdepFromPrefs();
    await getdata();
  }

  Map<String, Map<String, dynamic>> familyWiseSummary = {};
  Map<String, Map<String, dynamic>> todayFamilyWiseSummary = {};
  Map<String, Map<String, dynamic>> currentMonthFamilySummary = {};
  Map<String, Map<String, dynamic>> currentMonthFamilyWiseSummary = {};

  int approval = 0;
  int confirm = 0;
  int approvalcount = 0;
  int confirmcount = 0;
  Map<String, dynamic>? productsData;

  Future<void> getdata() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/orders/summary/family/data/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        // Store overall summary
        setState(() {
          productsData = parsed['overall'];
          // Build today's family summary map
          todayFamilyWiseSummary = {};
          for (var family in parsed['results']) {
            todayFamilyWiseSummary[family['family_name']] = {
              'order_count': family['today_count'],
              'total_amount': family['today_total_amount'],
              'cod_order_count': family['payment_status_summary']['today']
                  ['COD']['count'],
              'cod_total_amount': family['payment_status_summary']['today']
                  ['COD']['total'],
              'paid_order_count': family['payment_status_summary']['today']
                  ['paid']['count'],
              'paid_total_amount': family['payment_status_summary']['today']
                  ['paid']['total'],
              'credit_order_count': family['payment_status_summary']['today']
                  ['credit']['count'],
              'credit_total_amount': family['payment_status_summary']['today']
                  ['credit']['total'],
            };
          }
        });
      }
    } catch (error) {}
  }

  Future<bool> checkAppUpdate(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    try {
      final response = await http.get(Uri.parse(
        'https://play.google.com/store/apps/details?id=com.bepositive.beposoft&hl=en',
      ));

      if (response.statusCode == 200) {
        final content = response.body;
        final versionRegex = RegExp(r'\[\[\["([0-9.]+)"\]\]');
        final match = versionRegex.firstMatch(content);

        if (match != null) {
          final storeVersion = match.group(1);
          if (storeVersion != null && storeVersion != currentVersion) {
            final result = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                titlePadding: const EdgeInsets.only(top: 20),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                title: Column(
                  children: [
                    Icon(Icons.system_update, size: 48, color: Colors.green),
                    const SizedBox(height: 10),
                    const Text(
                      'Update Available',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                content: Text(
                  'A new version ($storeVersion) is available.\n\nYou are using $currentVersion.\n\nPlease update the app to continue enjoying the latest features and improvements.',
                  style: const TextStyle(fontSize: 16),
                ),
                actionsAlignment: MainAxisAlignment.spaceEvenly,
                actions: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    label: const Text("Update Now"),
                    onPressed: () async {
                      final playStoreUrl = Uri.parse(
                          'https://play.google.com/store/apps/details?id=com.bepositive.beposoft');
                      if (await canLaunchUrl(playStoreUrl)) {
                        await launchUrl(playStoreUrl,
                            mode: LaunchMode.externalApplication);
                      }
                      Navigator.of(context)
                          .pop(false); // Prevent app from loading
                    },
                  ),
                  TextButton(
                    child: const Text("Maybe Later"),
                    onPressed: () =>
                        Navigator.of(context).pop(true), // Continue with app
                  ),
                ],
              ),
            );
            return result == true;
          }
        }
      }
    } catch (e) {
      // Optionally log error
    }

    return true; // Proceed normally if no update
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Future<void> fetchOrderData() async {
  //   try {
  //     final token = await getTokenFromPrefs();
  //     var response = await http.get(
  //       Uri.parse('$api/api/orders/'),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       final parsed = jsonDecode(response.body);
  //       var productsData = parsed['results'];

  //       if (productsData != null && productsData is Iterable) {
  //         List<Map<String, dynamic>> orderList = [];
  //         Map<String, Map<String, dynamic>> familySummary = {};
  //         Map<String, Map<String, dynamic>> todayFamilySummary = {};
  //         Map<String, Map<String, dynamic>> currentMonthFamilySummary = {};
  //         double todayCodTotalAmount = 0.0;
  //         int todayCodOrderCount = 0;

  //         double monthCodTotalAmount = 0.0;
  //         int monthCodOrderCount = 0;
  //    double monthpaidTotalAmount = 0.0;
  //         int monthpaidOrderCount = 0;
  //         double monthcrediTotalAmount = 0.0;
  //         int monthcreditOrderCount = 0;
  //         int approval = 0;
  //         int confirm = 0;

  //         DateTime today = DateTime.now();
  //         String formattedToday = DateFormat('yyyy-MM-dd').format(today);

  //         for (var productData in productsData) {
  //           // Parse order_date
  //           String rawOrderDate = productData['order_date'];
  //           String formattedOrderDate = rawOrderDate;
  //           try {
  //             DateTime parsedOrderDate = DateTime.parse(rawOrderDate);
  //             formattedOrderDate =
  //                 DateFormat('yyyy-MM-dd').format(parsedOrderDate);
  //           } catch (e) {
  //             // Handle parsing error if needed
  //           }

  //           // Build order entry
  //           var order = {
  //             'id': productData['id'],
  //             'invoice': productData['invoice'],
  //             'manage_staff': productData['manage_staff'],
  //             'customer': {
  //               'id': productData['customer']['id'],
  //               'name': productData['customer']['name'],
  //               'address': productData['billing_address']?['address'] ?? '',
  //             },
  //             'status': productData['status'],
  //             'order_date': formattedOrderDate,
  //             'updated_at': productData['updated_at'],
  //             'total_amount': productData['total_amount'],
  //             'family': productData['family'],
  //             'payment_status': productData['payment_status'],
  //           };

  //           orderList.add(order);

  //           // Count invoice statuses
  //           if (productData['status'] == 'Invoice Created') {
  //             approval++;
  //           } else if (productData['status'] == 'Invoice Approved') {
  //             confirm++;
  //           }

  //           // All-time Family-wise Summary
  //           String family = productData['family'];
  //           double amount =
  //               double.tryParse(productData['total_amount'].toString()) ?? 0.0;

  //           // Current Month's Family-wise Summary
  //           DateTime parsedOrderDate;
  //           try {
  //             parsedOrderDate = DateTime.parse(rawOrderDate);
  //           } catch (e) {
  //             parsedOrderDate = today; // fallback to avoid crash
  //           }

  //           if (parsedOrderDate.month == today.month &&
  //               parsedOrderDate.year == today.year) {
  //             currentMonthFamilySummary.putIfAbsent(
  //                 family,
  //                 () => {
  //                       'total_amount': 0.0,
  //                       'order_count': 0,
  //                       'cod_order_count': 0,
  //                       'cod_total_amount': 0.0,
  //                       'paid_order_count': 0,
  //                       'paid_total_amount': 0.0,
  //                       'credit_order_count': 0,
  //                       'credit_total_amount': 0.0,
  //                     });
  //             currentMonthFamilySummary[family]!['total_amount'] += amount;
  //             currentMonthFamilySummary[family]!['order_count'] += 1;
  //             if (productData['payment_status'] == 'COD') {
  //               currentMonthFamilySummary[family]!['cod_order_count'] += 1;
  //               currentMonthFamilySummary[family]!['cod_total_amount'] +=
  //                   amount;
  //             }

  //              if (productData['payment_status'] == 'paid') {
  //               currentMonthFamilySummary[family]!['paid_order_count'] += 1;
  //               currentMonthFamilySummary[family]!['paid_total_amount'] +=
  //                   amount;
  //             }
  //             if (productData['payment_status'] == 'credit') {
  //               currentMonthFamilySummary[family]!['credit_order_count'] += 1;
  //               currentMonthFamilySummary[family]!['credit_total_amount'] +=
  //                   amount;
  //             }
  //           }

  //           familySummary.putIfAbsent(
  //               family,
  //               () => {
  //                     'total_amount': 0.0,
  //                     'order_count': 0,
  //                   });
  //           familySummary[family]!['total_amount'] += amount;
  //           familySummary[family]!['order_count'] += 1;

  //           // Today's Family-wise Summary
  //           if (formattedOrderDate == formattedToday) {
  //             todayFamilySummary.putIfAbsent(
  //                 family,
  //                 () => {
  //                       'total_amount': 0.0,
  //                       'order_count': 0,
  //                       'cod_order_count': 0,
  //                       'cod_total_amount': 0.0,
  //                       'paid_order_count': 0,
  //                       'paid_total_amount': 0.0,
  //                       'credit_order_count': 0,
  //                       'credit_total_amount': 0.0,
  //                     });
  //             todayFamilySummary[family]!['total_amount'] += amount;
  //             todayFamilySummary[family]!['order_count'] += 1;
  //             if (productData['payment_status'] == 'COD') {
  //               todayFamilySummary[family]!['cod_order_count'] += 1;
  //               todayFamilySummary[family]!['cod_total_amount'] += amount;
  //             }
  //             if (productData['payment_status'] == 'paid') {
  //               todayFamilySummary[family]!['paid_order_count'] += 1;
  //               todayFamilySummary[family]!['paid_total_amount'] += amount;
  //             }
  //             if (productData['payment_status'] == 'credit') {
  //               todayFamilySummary[family]!['credit_order_count'] += 1;
  //               todayFamilySummary[family]!['credit_total_amount'] += amount;
  //             }
  //           }
  //         }

  //         // Shipped Orders Today (using updated_at)
  //         var shippedOrdersToday = orderList.where((order) {
  //           return order['status'] == 'Shipped' &&
  //               order['updated_at'].startsWith(formattedToday);
  //         }).toList();

  //         // Add total row to currentMonthFamilySummary
  //         double monthTotalAmount = 0.0;
  //         int monthTotalOrders = 0;

  //         currentMonthFamilySummary.forEach((key, value) {
  //           if (key == 'Total') return; // Avoid adding previous total row
  //           monthTotalAmount += (value['total_amount'] as double);
  //           monthTotalOrders += (value['order_count'] as int);
  //           monthCodTotalAmount +=
  //               (value['cod_total_amount'] as double? ?? 0.0);
  //           monthCodOrderCount += (value['cod_order_count'] as int? ?? 0);
  //           monthpaidTotalAmount +=
  //               (value['paid_total_amount'] as double? ?? 0.0);
  //           monthpaidOrderCount += (value['paid_order_count'] as int? ?? 0);
  //           monthcrediTotalAmount +=
  //               (value['credit_total_amount'] as double? ?? 0.0);
  //           monthcreditOrderCount += (value['credit_order_count'] as int? ?? 0);
  //         });

  //         currentMonthFamilySummary['Month Total'] = {
  //           'total_amount': monthTotalAmount,
  //           'order_count': monthTotalOrders,
  //           'cod_total_amount': monthCodTotalAmount,
  //           'cod_order_count': monthCodOrderCount,
  //           'paid_total_amount': monthpaidTotalAmount,
  //           'paid_order_count': monthpaidOrderCount,
  //           'credit_total_amount': monthcrediTotalAmount,
  //           'credit_order_count': monthcreditOrderCount,
  //         };

  //         // Set all states
  //         setState(() {
  //           orders = orderList;
  //           filteredOrders = orderList;
  //           shippedOrders = shippedOrdersToday;
  //           approvalcount = parsed['invoice_created_count'];
  //           confirmcount = parsed['invoice_approved_count'];
  //           familyWiseSummary = familySummary;
  //           todayFamilyWiseSummary = todayFamilySummary;
  //           currentMonthFamilyWiseSummary = currentMonthFamilyWiseSummary;
  //         });
  //       }
  //     }
  //   } catch (error) {
  //     // Optionally show a snackbar or alert here
  //   }
  // }

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
    } else if (dep == "CSO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                cso_dashboard()), // Replace AnotherPage with your target page
      );
    } else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                WarehouseAdmin()), // Replace AnotherPage with your target page
      );
    } else if (dep == "Marketing") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                marketing_dashboard()), // Replace AnotherPage with your target page
      );
    } else {
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
        backgroundColor: const Color.fromARGB(255, 252, 247, 247),
        appBar: AppBar(
          title: Text(
            "Today's Family Summary",
            style: TextStyle(color: Colors.grey, fontSize: 14),
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
              } else if (dep == "CSO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          cso_dashboard()), // Replace AnotherPage with your target page
                );
              } else if (dep == "Warehouse Admin") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          WarehouseAdmin()), // Replace AnotherPage with your target page
                );
              } else if (dep == "Marketing") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          marketing_dashboard()), // Replace AnotherPage with your target page
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
        ),
        body: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section

                  // Add this after your info cards in the build method, e.g. after SizedBox(height: 10),
                  if (todayFamilyWiseSummary.isNotEmpty) ...[
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: todayFamilyWiseSummary.length,
                      itemBuilder: (context, index) {
                        String family =
                            todayFamilyWiseSummary.keys.elementAt(index);
                        var summary = todayFamilyWiseSummary[family]!;

                        return TweenAnimationBuilder<Offset>(
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          tween: Tween<Offset>(
                              begin: Offset(-1, 0), end: Offset(0, 0)),
                          curve: Curves.easeOut,
                          builder: (context, offset, child) {
                            return Transform.translate(
                              offset: offset * 20,
                              child: child,
                            );
                          },
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => familysummary(
                                      family: family, status: null),
                                ),
                              );
                            },
                            child: Card(
                              color: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title with gradient background
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 8),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF02347C),
                                            Color(0xFF82E49D),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        family.toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.white, // Heading text in white
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Table with borders
                                    Table(
                                      columnWidths: const {
                                        0: FlexColumnWidth(2), // Label
                                        1: FlexColumnWidth(1), // Count
                                        2: FlexColumnWidth(2), // Amount
                                      },
                                      border: TableBorder.all(
                                        color: Colors.grey.shade400,
                                        width: 1,
                                      ),
                                      children: [
                                        // Header row
                                        const TableRow(
                                          decoration: BoxDecoration(
                                              color: Color(0xFFEFEFEF)),
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.all(6),
                                              child: Text("Type",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(6),
                                              child: Text("Count",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(6),
                                              child: Text("Amount",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          ],
                                        ),

                                        if (summary
                                            .containsKey('cod_order_count'))
                                          TableRow(children: [
                                            Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.local_shipping,
                                                      size: 14,
                                                      color: Colors.brown),
                                                  SizedBox(width: 5),
                                                  Text("COD"),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Text(
                                                  "${summary['cod_order_count']}"),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Text(
                                                "₹${summary['cod_total_amount'].toStringAsFixed(2)}",
                                                style: TextStyle(
                                                    color:
                                                        Colors.brown.shade700),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          ]),
                                        TableRow(children: [
                                          Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: Row(
                                              children: const [
                                                Icon(Icons.payments,
                                                    size: 16,
                                                    color: Colors.green),
                                                SizedBox(width: 5),
                                                Text("Cash"),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: Text(
                                                "${summary['paid_order_count']}"),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: Text(
                                              "₹${summary['paid_total_amount'].toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                  color: Colors.green),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ]),
                                        TableRow(children: [
                                          Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: Row(
                                              children: const [
                                                Icon(Icons.paid,
                                                    size: 16,
                                                    color: Colors.teal),
                                                SizedBox(width: 5),
                                                Text("Credit"),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: Text(
                                                "${summary['credit_order_count']}"),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: Text(
                                              "₹${summary['credit_total_amount'].toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                  color: Colors.teal),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ]),
                                        TableRow(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF02347C),
                                                Color(0xFF82E49D),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.list_alt, size: 16, color: Colors.white),
                                                  SizedBox(width: 5),
                                                  Text(
                                                    "Total",
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Text(
                                                "${summary['order_count']}",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Text(
                                                "₹${summary['total_amount'].toStringAsFixed(2)}",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    /// COD + Paid Summary Box
                    Builder(builder: (context) {
                      if (productsData == null) return SizedBox.shrink();

                      final todaySummary =
                          productsData?['payment_status_summary']?['today'] ??
                              {};
                      final codOrderCount = todaySummary['COD']?['count'] ?? 0;
                      final codTotalAmount =
                          todaySummary['COD']?['total'] ?? 0.0;
                      final paidOrderCount =
                          todaySummary['paid']?['count'] ?? 0;
                      final paidTotalAmount =
                          todaySummary['paid']?['total'] ?? 0.0;
                      final creditOrderCount =
                          todaySummary['credit']?['count'] ?? 0;
                      final creditTotalAmount =
                          todaySummary['credit']?['total'] ?? 0.0;

                      final grandTotalOrders =
                          (productsData?['today_count'] ?? 0);
                      final grandTotalAmount =
                          (productsData?['today_total_amount'] ?? 0.0);

                      return Container(
                        margin: const EdgeInsets.only(
                            top: 8, left: 6, right: 6, bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF02347C),
                              Color(0xFF82E49D),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade100,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.payments,
                                    color: Colors.white, size: 15),
                                SizedBox(width: 8),
                                Text(
                                  "Today's Total Summary",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.date_range,
                                    color: Colors.white, size: 15),
                                const SizedBox(width: 8),
                                Text(
                                  "${DateFormat('dd/MM/yyyy').format(DateTime.now())}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white60),
                            const SizedBox(height: 10),

                            // TABLE FORMAT
                            Table(
                              border: TableBorder.all(
                                  color: Colors.white60, width: 1),
                              columnWidths: const {
                                0: FlexColumnWidth(2), // Type
                                1: FlexColumnWidth(1), // Count
                                2: FlexColumnWidth(2), // Amount
                              },
                              children: [
                                // Header
                                const TableRow(
                                  decoration:
                                      BoxDecoration(color: Colors.white24),
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Text("Type",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Text("Count",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Text("Amount",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                    ),
                                  ],
                                ),

                                // COD Row
                                TableRow(children: [
                                  const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Text("COD",
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.white)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text("$codOrderCount",
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(
                                        "₹${codTotalAmount.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                            color: Colors.white),
                                        textAlign: TextAlign.right),
                                  ),
                              ]),

                                // Paid Row
                                TableRow(children: [
                                  const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Text("Paid",
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.white)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text("$paidOrderCount",
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(
                                        "₹${paidTotalAmount.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                            color: Colors.white),
                                        textAlign: TextAlign.right),
                                  ),
                              ]),

                                // Credit Row
                                TableRow(children: [
                                  const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Text("Credit",
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.white)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text("$creditOrderCount",
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(
                                        "₹${creditTotalAmount.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                            color: Colors.white),
                                        textAlign: TextAlign.right),
                                  ),
                              ]),

                                // Grand Total Row (highlighted)
                                TableRow(
                                  decoration: const BoxDecoration(
                                      color: Colors.white30),
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Text("Grand Total",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Text("$grandTotalOrders",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Text(
                                          "₹${grandTotalAmount.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                          textAlign: TextAlign.right),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    })
                  ],
                  if (todayFamilyWiseSummary.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 50.0),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              "Data is fetching...",
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String value, String label, int notificationCount) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (notificationCount > 0)
              Positioned(
                top: -8,
                right: -8,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.red,
                  child: Text(
                    notificationCount.toString(),
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem(IconData icon, String title, [int? count]) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Stack(
          clipBehavior: Clip.none, // Prevents the badge from clipping the card
          children: [
            // Main content of the card - Center the text and icon
            Center(
              // Wrap the Column in a Center widget
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Vertically center
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Horizontally center
                children: [
                  Icon(icon, size: 36, color: Colors.blue),
                  SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Notification Badge
            if (count != null && count > 0)
              Positioned(
                top: -8,
                right: -8,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[600],
                  child: Text(
                    count.toString(),
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Widget _buildCardWithIcon({
  required String label,
  required String value,
  Color color = Colors.white,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(height: 6),
      Text(
        value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color.withOpacity(0.9),
        ),
      ),
    ],
  );
}

Widget _buildRowWithTwoColumns(
    String label1, dynamic value1, String label2, dynamic value2) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label1,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              Text(
                value1.toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label2,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              Text(
                value2.toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildTableHeader(String label) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Center(
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

Widget _buildTableCell(String value, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Center(
      child: Text(
        value,
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        Text(
          value,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    ),
  );
}

Widget _buildInfoColumn(String label, String value) {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
