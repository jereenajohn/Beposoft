import 'dart:convert';
import 'dart:io';
import 'package:beposoft/pages/ACCOUNTS/add_self_attendance.dart';
import 'package:beposoft/pages/ACCOUNTS/mailboxpage..dart';
import 'package:beposoft/pages/ADMIN/add_attendance.dart';
import 'package:beposoft/pages/ADMIN/add_staffwise_department.dart';
import 'package:beposoft/pages/ADMIN/add_team_staff.dart';
import 'package:beposoft/pages/ADMIN/manager_leave_requestpage.dart';
import 'package:beposoft/pages/auth_status_checker.dart';

import 'package:beposoft/pages/ACCOUNTS/Bulk_Bepocart_Orders.dart';
import 'package:beposoft/pages/ACCOUNTS/Create_Purchase_Product_List.dart';
import 'package:beposoft/pages/ACCOUNTS/Today_shipped_orders.dart';
import 'package:beposoft/pages/ACCOUNTS/activity_log.dart';
import 'package:beposoft/pages/ACCOUNTS/add_EMI.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank_type.dart';
import 'package:beposoft/pages/ACCOUNTS/add_category.dart';
import 'package:beposoft/pages/ACCOUNTS/add_country_code.dart' show add_country;
import 'package:beposoft/pages/ACCOUNTS/add_currency.dart';
import 'package:beposoft/pages/ACCOUNTS/add_daily_sales_report.dart';
import 'package:beposoft/pages/ACCOUNTS/add_purpose_of_payment.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supplier.dart';
import 'package:beposoft/pages/ACCOUNTS/add_warehouse.dart';
import 'package:beposoft/pages/ACCOUNTS/addrack.dart';
import 'package:beposoft/pages/ACCOUNTS/all_users_categorywise_sales_report.dart';
import 'package:beposoft/pages/ACCOUNTS/all_users_sales_report.dart';
import 'package:beposoft/pages/ACCOUNTS/assetmanagement.dart';
import 'package:beposoft/pages/ACCOUNTS/assetmanegment2.dart';
import 'package:beposoft/pages/ACCOUNTS/bulk_customer_upload.dart';
import 'package:beposoft/pages/ACCOUNTS/call_log.dart';
import 'package:beposoft/pages/ACCOUNTS/categorywise_sales_report.dart';
import 'package:beposoft/pages/ACCOUNTS/daily_bdo_sales_report.dart';
import 'package:beposoft/pages/ACCOUNTS/dailyproductcategorywisecyclingskating.dart';
// import 'package:beposoft/pages/ACCOUNTS/call_log.dart';
import 'package:beposoft/pages/ACCOUNTS/graph.dart';
import 'package:beposoft/pages/ACCOUNTS/grv_list.dart';
import 'package:beposoft/pages/ACCOUNTS/order_list.dart';
import 'package:beposoft/pages/ACCOUNTS/seller_purchase_invoice_list.dart';
import 'package:beposoft/pages/ACCOUNTS/status_wise_orders_list.dart';
import 'package:beposoft/pages/ACCOUNTS/performa_invoice_list.dart';
import 'package:beposoft/pages/ACCOUNTS/todays_orders_list.dart';
import 'package:beposoft/pages/ACCOUNTS/uploadbulkorders.dart';
import 'package:beposoft/pages/BDO/EmployeeLeaveFormPage%20.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_product_approval.dart';
import 'package:beposoft/pages/logout_hekper.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
import 'dart:async';

class dashboard extends StatefulWidget {
  @override
  State<dashboard> createState() => _admin_dashboardState();
}

class _admin_dashboardState extends State<dashboard>
    with WidgetsBindingObserver {
        List<String> statusOptions = ["pending", "approved", "rejected"];
  List<Map<String, dynamic>> grvlist = [];
  List<Map<String, dynamic>> proforma = [];
  List<Map<String, dynamic>> salesReportList = [];
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  List<Map<String, dynamic>> shippedOrders = [];
  bool isManager = false;
  int inboxMailCount = 0;
  Timer? mailCountTimer;
  bool isFetchingInboxMailCount = false;
  String? username = '';
  String profileImage = '';
@override
void initState() {
  super.initState();

  WidgetsBinding.instance.addObserver(this);

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    checkAppUpdate(context);
  });

  _getUsername();
  getGrvList();
  fetchproformaData();
  getSalesReport();
  getProfile();
  fetchOrderData();
  fetchshippedorders();

  fetchInboxMailCount();

  mailCountTimer = Timer.periodic(
    const Duration(seconds: 15),
    (_) {
      if (mounted) {
        fetchInboxMailCount();
      }
    },
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    AuthStatusChecker.start(context);
  });
}
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  super.didChangeAppLifecycleState(state);

  if (state == AppLifecycleState.resumed) {
    fetchInboxMailCount();
  }
}
  @override
  void dispose() {
    mailCountTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

 Future<void> fetchInboxMailCount() async {
  if (isFetchingInboxMailCount) return;

  isFetchingInboxMailCount = true;

  try {
    final String? token = await getTokenFromPrefs();

    if (token == null || token.trim().isEmpty) {
      return;
    }

    final Uri uri = Uri.parse(
      '$api/api/internal/mails/',
    ).replace(
      queryParameters: {
        'type': 'inbox',
        'read_status': 'unread',
        'page': '1',
      },
    );

    final http.Response response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      debugPrint(
        'MAIL COUNT REQUEST FAILED: '
        '${response.statusCode} ${response.body}',
      );
      return;
    }

    final dynamic decoded = jsonDecode(response.body);

    int newUnreadCount = 0;

    if (decoded is Map<String, dynamic>) {
      final dynamic results = decoded['results'];
      final dynamic data = decoded['data'];

      final dynamic rawUnreadCount =
          decoded['unread_count'] ??
          (results is Map ? results['unread_count'] : null) ??
          (data is Map ? data['unread_count'] : null);

      final dynamic rawFilteredCount =
          decoded['count'] ??
          (results is Map ? results['count'] : null) ??
          (data is Map ? data['count'] : null);

      if (rawUnreadCount != null) {
        newUnreadCount =
            rawUnreadCount is int
                ? rawUnreadCount
                : int.tryParse(rawUnreadCount.toString()) ?? 0;
      } else if (rawFilteredCount != null) {
        /*
         * Since the API request contains read_status=unread,
         * this count represents unread mails.
         */
        newUnreadCount =
            rawFilteredCount is int
                ? rawFilteredCount
                : int.tryParse(rawFilteredCount.toString()) ?? 0;
      } else {
        dynamic mailList;

        if (results is Map && results['data'] is List) {
          mailList = results['data'];
        } else if (data is Map && data['data'] is List) {
          mailList = data['data'];
        } else if (results is List) {
          mailList = results;
        } else if (data is List) {
          mailList = data;
        }

        if (mailList is List) {
          newUnreadCount = mailList.where((dynamic mail) {
            if (mail is! Map) return false;

            if (mail.containsKey('is_read')) {
              return mail['is_read'] != true;
            }

            if (mail.containsKey('read')) {
              return mail['read'] != true;
            }

            final dynamic readAt = mail['read_at'];

            return readAt == null ||
                readAt.toString().trim().isEmpty;
          }).length;
        }
      }
    }

    if (!mounted) return;

    if (inboxMailCount != newUnreadCount) {
      setState(() {
        inboxMailCount = newUnreadCount;
      });
    }
  } catch (error, stackTrace) {
    debugPrint('MAIL COUNT ERROR: $error');
    debugPrintStack(stackTrace: stackTrace);
  } finally {
    isFetchingInboxMailCount = false;
  }
}

  Future<void> getProfile() async {
    try {
      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final data = parsed['data'];

        setState(() {
          isManager = data['is_manager'] ?? false;
          profileImage = data['image']?.toString() ?? '';
        });

        debugPrint("IS MANAGER : $isManager");
        debugPrint("PROFILE IMAGE : $profileImage");
      }
    } catch (e) {
      debugPrint("PROFILE ERROR : $e");
    }
  }

  String getProfileImageUrl() {
    if (profileImage.trim().isEmpty) return '';
    if (profileImage.startsWith('http')) return profileImage;
    return '$api$profileImage';
  }

  int approval = 0;
  int confirm = 0;
  int approvalcount = 0;
  int confirmcount = 0;
  Future<void> fetchOrderData() async {
    try {
      final token = await getTokenFromPrefs();
      var response = await http.get(
        Uri.parse('$api/api/orders/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData =
            parsed['results']; // Corrected: Extracting orders from 'results'

        if (productsData != null && productsData is Iterable) {
          List<Map<String, dynamic>> orderList = [];

          for (var productData in productsData) {
            String rawOrderDate = productData['updated_at'];
            String formattedOrderDate = rawOrderDate;

            try {
              DateTime parsedOrderDate =
                  DateFormat('yyyy-MM-dd').parse(rawOrderDate);
              formattedOrderDate =
                  DateFormat('yyyy-MM-dd').format(parsedOrderDate);
            } catch (e) {
              ;
            }

            orderList.add({
              'id': productData['id'],
              'invoice': productData['invoice'],
              'manage_staff': productData['manage_staff'],
              'customer': {
                'id': productData['customer']['id'],
                'name': productData['customer']['name'],
              },
              'status': productData['status'],
              'order_date': formattedOrderDate,
              'total_amount': productData['total_amount'],
            });

            if (productData['status'] == 'Invoice Created') {
              approval++;
            } else if (productData['status'] == 'Invoice Approved') {
              confirm++;
            }
          }

          DateTime today = DateTime.now();
          String formattedToday = DateFormat('yyyy-MM-dd').format(today);

          var shippedOrdersToday = orderList.where((order) {
            return order['status'] == 'Shipped' &&
                order['updated_at'] == formattedToday;
          }).toList();

          setState(() {
            orders = orderList;
            filteredOrders = orderList;
            shippedOrders = shippedOrdersToday;
            ;
            approvalcount = parsed['invoice_created_count'];
            confirmcount = parsed['invoice_approved_count'];
            ;
            ;
          });
        } else {
          ;
        }
      }
    } catch (error) {
      // print("Error fetching order data: $error");
      // ;
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Error fetching order data: $error')),
      //   );
      // });
    }
  }

  int todayShippedCount = 0;
  Future<void> fetchshippedorders() async {
    try {
      final token = await getTokenFromPrefs();

      String url = '$api/api/orders/';

      var response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List ordersData = responseData['results'];

        DateTime currentDate = DateTime.now();
        String today = DateFormat('yyyy-MM-dd').format(currentDate);

        int shippedTodayCount = 0;

        for (var orderData in ordersData) {
          String rawOrderDate = orderData['order_date'] ?? "";
          try {
            DateTime parsedOrderDate =
                DateFormat('yyyy-MM-dd').parse(rawOrderDate);
            String formattedOrderDate =
                DateFormat('yyyy-MM-dd').format(parsedOrderDate);

            if (formattedOrderDate == today &&
                orderData['status'] == "Shipped") {
              shippedTodayCount++;
            }
          } catch (e) {
            continue;
          }
        }

        // Now you can use `shippedTodayCount` as needed

        setState(() {
          todayShippedCount =
              shippedTodayCount; // ← Make sure to define this in your state
        });
      } else {
        throw Exception("Failed to load order data");
      }
    } catch (error) {}
  }

  Future<void> getSalesReport() async {
    setState(() {}); // Keep the loading state if needed
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/salesreport/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      ;

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        // Corrected the key
        var salesData = parsed['sales_report'];

        if (salesData != null && salesData is Iterable) {
          List<Map<String, dynamic>> salesReportDataList = [];
          for (var reportData in salesData) {
            salesReportDataList.add({
              'date': reportData['date'],
              'total_bills_in_date': reportData['total_bills_in_date'],
              'amount': reportData['amount'],
              'approved': {
                'bills': reportData['approved']['bills'],
                'amount': reportData['approved']['amount']
              },
              'rejected': {
                'bills': reportData['rejected']['bills'],
                'amount': reportData['rejected']['amount']
              }
            });
          }

          setState(() {
            salesReportList = salesReportDataList;
            ;
          });
          getTodaysBills(); // Get today's bills count
        }
      }
    } catch (error) {
      ;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('An error occurred while fetching data')),
        //);
      });
    } finally {
      setState(() {}); // End loading state
    }
  }

  var totalbills = "0";
  void getTodaysBills() {
    // Get today's date in the same format as in the response (yyyy-MM-dd)
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Find today's report entry
    var todaysReport = salesReportList.firstWhere(
      (report) => report['date'] == currentDate,
      orElse: () => {}, // Return null if no report for today
    );
    setState(() {
      if (todaysReport['total_bills_in_date'] != null) {
        totalbills = todaysReport['total_bills_in_date'].toString();
        ;
      } else {
        totalbills = '0'; // Return '0' if no report is found for today
      }
    });
  }

  Future<void> fetchproformaData() async {
    try {
      final token = await getTokenFromPrefs();
      final response = await http.get(
        Uri.parse('$api/api/perfoma/invoices/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final data = parsed['data'] as List;

        List<Map<String, dynamic>> performaInvoiceList = [];

        for (var productData in data) {
          performaInvoiceList.add({
            'id': productData['id'],
            'invoice': productData['invoice'],
            'manage_staff': productData['manage_staff'],
            'customer_name': productData['customer']['name'],
            'status': productData['status'],
            'total_amount': productData['total_amount'],
            'order_date': productData['order_date'],
            'created_at': productData['customer']['created_at'],
          });
        }

        setState(() {
          proforma = performaInvoiceList;
        });
        int proformalistcount = proforma.length;
      } else {}
    } catch (error) {}
  }

// Get token from SharedPreferences
  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  int grv = 0;
  int grvcount = 0;
// Function to fetch GRV data
  Future<void> getGrvList() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/grv/data/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      ;
      ;
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        List<Map<String, dynamic>> grvDataList = [];
        for (var productData in productsData) {
          grvDataList.add({
            'id': productData['id'],
            'product': productData['product'],
            'returnreason': productData['returnreason'],
            'invoice': productData['invoice'],
            'customer': productData['customer'],
            'staff': productData['staff'],
            'remark': productData['remark'],
            'status': productData['status'] ?? statusOptions[0],
            'order_date': productData['order_date'],
          });
          if (productData['status'] == "pending") {
            grv = grv + 1;
          }
        }
        setState(() {
          grvlist = grvDataList;
          grvcount = grv;
        });

        // Get the count of grvlist
        int grvListCount = grvlist.length;
      } else {}
    } catch (error) {}
  }

  // Retrieve the username from SharedPreferences
  Future<void> _getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ??
          'Guest'; // Default to 'Guest' if no username
    });
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.remove('userId');
    // await prefs.remove('token');
    // await prefs.remove('username');
    //   await prefs.remove('department');

    // Use a post-frame callback to show the SnackBar after the current frame
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (ScaffoldMessenger.of(context).mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text('Logged out successfully'),
    //         duration: Duration(seconds: 2),
    //       ),
    //     );
    //   }
    // });

    // // Wait for the SnackBar to disappear before navigating
    // await Future.delayed(Duration(seconds: 2));

    // Navigate to the HomePage after the snackbar is shown
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login()),
    );
  }

  drower d = drower();

  Widget _buildDropdownTile(
      BuildContext context, String title, List<String> options) {
    return ExpansionTile(
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.white,
      iconColor: Colors.black,
      collapsedIconColor: Colors.black,
      title: Text(
        title,
        style: const TextStyle(color: Colors.black),
      ),
      children: options.map((option) {
        return ListTile(
          tileColor: Colors.white,
          title: Text(
            option,
            style: const TextStyle(color: Colors.black),
          ),
          onTap: () {
            Navigator.pop(context);
            d.navigateToSelectedPage(context, option);
          },
        );
      }).toList(),
    );
  }

  Future<bool> checkAppUpdate(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    try {
      String? storeVersion;
      Uri? storeUrl;

      if (Platform.isAndroid) {
        final response = await http.get(Uri.parse(
          'https://play.google.com/store/apps/details?id=com.bepositive.beposoft&hl=en',
        ));

        if (response.statusCode == 200) {
          final content = response.body;
          final versionRegex = RegExp(r'\[\[\["([0-9.]+)"\]\]');
          final match = versionRegex.firstMatch(content);

          if (match != null) {
            storeVersion = match.group(1);
            storeUrl = Uri.parse(
              'https://play.google.com/store/apps/details?id=com.bepositive.beposoft',
            );
          }
        }
      } else if (Platform.isIOS) {
        final response = await http.get(
          Uri.parse('https://itunes.apple.com/lookup?id=6748010646&country=in'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['resultCount'] != null &&
              data['resultCount'] > 0 &&
              data['results'] != null &&
              data['results'] is List &&
              data['results'].isNotEmpty) {
            final appData = data['results'][0];
            storeVersion = appData['version']?.toString();
            storeUrl = Uri.parse(
              'https://apps.apple.com/in/app/beposoft/id6748010646',
            );
          }
        }
      }

      if (storeVersion != null &&
          _isUpdateAvailable(currentVersion, storeVersion)) {
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
                Icon(
                  Icons.system_update,
                  size: 48,
                  color: Colors.green,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Update Available',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
                  if (storeUrl != null && await canLaunchUrl(storeUrl)) {
                    await launchUrl(
                      storeUrl,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text("Maybe Later"),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );

        return result == true;
      }
    } catch (e) {
      // Optional: print(e);
    }

    return true;
  }

  bool _isUpdateAvailable(String currentVersion, String storeVersion) {
    List<int> currentParts =
        currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    List<int> storeParts =
        storeVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    int maxLength = currentParts.length > storeParts.length
        ? currentParts.length
        : storeParts.length;

    while (currentParts.length < maxLength) {
      currentParts.add(0);
    }
    while (storeParts.length < maxLength) {
      storeParts.add(0);
    }

    for (int i = 0; i < maxLength; i++) {
      if (storeParts[i] > currentParts[i]) {
        return true;
      } else if (storeParts[i] < currentParts[i]) {
        return false;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          // leading: Icon(Icons.arrow_back, color: Colors.black),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.mail_outline_rounded,
                      color: Colors.black,
                      size: 28,
                    ),
                 onPressed: () async {
  await Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => const StaffMailPage(),
    ),
  );

  if (!mounted) return;

  await fetchInboxMailCount();
},
                  ),
                  if (inboxMailCount > 0)
                    Positioned(
                      right: 4,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          inboxMailCount > 99
                              ? '99+'
                              : inboxMailCount.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
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
        drawer: Drawer(
          backgroundColor: Colors.white,
          child: Container(
            color: Colors.white,
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          "lib/assets/appstore.png",
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
                // ListTile(
                //   leading: Icon(Icons.dashboard),
                //   title: Text('Dashboard'),
                //   onTap: () {
                //     Navigator.push(context,
                //         MaterialPageRoute(builder: (context) => Graph()));
                //   },
                // ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Bulk'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => OrderBulkUpload()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Add Attendance'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => StaffSelfAttendanceScreen()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),

                if (isManager)
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Add Attendance Dept'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AttendanceDepartmentPage(
                                    baseUrl: api,
                                  )));
                      // Navigate to the Settings page or perform any other action
                    },
                  ),

                if (isManager)
                  ListTile(
                    leading: const Icon(Icons.group_add),
                    title: const Text('Add Team Staff'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StaffAttendanceTeamMemberScreen(),
                        ),
                      );
                    },
                  ),
                if (isManager)
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Add & Approve Attendance'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const StaffMarkAttendanceScreen(),
                        ),
                      );
                    },
                  ),
                if (isManager)
                  ListTile(
                    leading: const Icon(Icons.fact_check_outlined),
                    title: const Text('Approve Leave Request'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ManagerLeaveRequestsPage(),
                        ),
                      );
                    },
                  ),

                ListTile(
                  title: Text('Employee Leave Form'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EmployeeLeaveFormPage()));
                  },
                ),

            ListTile(
  title: const Text('Send Mail'),
  onTap: () async {
    Navigator.pop(context);

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => const StaffMailPage(),
      ),
    );

    if (!mounted) return;

    await fetchInboxMailCount();
  },
),

                _buildDropdownTile(context, 'Customers', [
                  'Add Customer',
                  'Customers',
                  'customer Transfer',
                  'customer Transfer list',
                  'Customer Type'
                ]),
                _buildDropdownTile(context, 'Recipt', [
                  'Add Recipt',
                  'Recipt List',
                  'Bank Recipt',
                  'Advance Recipt',
                  'Order Recipt',
                  'COD Transfer',
                  'COD Transfer List',
                ]),
                _buildDropdownTile(context, 'Refund', [
                  'Add Refund',
                  'Refund List',
                ]),

                _buildDropdownTile(context, 'Proforma Invoice', [
                  'New Proforma Invoice',
                  'Proforma Invoice List',
                ]),
                _buildDropdownTile(context, 'Delivery Note', [
                  'Delivery Note List(To Print)',
                  'Delivery Note List(Packing under Progress)',
                  'Delivery Note List(Packed)',
                  'Delivery Note List(Ready to ship)',
                  'Delivery Note List(Shipped)',
                  'Daily Goods Movement'
                ]),
                _buildDropdownTile(context, 'Orders', [
                  'New Orders',
                  'Orders List',
                  'Invoice Created',
                  'Invoice Approved',
                  'Pre Booked',
                  'Waiting For Confirmation',
                  'To Print',
                  'Packing Under Progress',
                  'Packed',
                  'Ready to ship',
                  'Shipped',
                  'Invoice Rejected'
                ]),
                Divider(),
                Text("Others"),
                Divider(),
                _buildDropdownTile(context, 'Purchase', [
                  'Product List',
                  'Purchase request',
                  'Purchase request List',
                  'Product Add',
                ]),
                _buildDropdownTile(context, 'Expence', [
                  'Add Expence',
                  'Expence List',
                ]),
                _buildDropdownTile(
                    context, 'GRV', ['Create New GRV', 'GRVs List']),

                _buildDropdownTile(context, 'Internal Transfer',
                    ['Add Transfer', 'Transfer List']),
                _buildDropdownTile(context, 'Daily Sales Reports',
                    ['Add Team Members', 'Add Team', 'Team wise Report']),

                // if (isManager)
                //   ListTile(
                //     title: Text('Add Attendance Department'),
                //     onTap: () {
                //       Navigator.push(
                //           context,
                //           MaterialPageRoute(
                //               builder: (context) => AttendanceDepartmentPage(
                //                     baseUrl: api,
                //                   )));
                //       // Navigate to the Settings page or perform any other action
                //     },
                //   ),

                // if (isManager)
                //   ListTile(
                //     leading: const Icon(Icons.group_add),
                //     title: const Text('Add Team Staff'),
                //     onTap: () {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) =>
                //               StaffAttendanceTeamMemberScreen(),
                //         ),
                //       );
                //     },
                //   ),
                // if (isManager)
                //   ListTile(
                //     leading: const Icon(Icons.fact_check_outlined),
                //     title: const Text('Add Attendance'),
                //     onTap: () {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) =>
                //               const StaffMarkAttendanceScreen(),
                //         ),
                //       );
                //     },
                //   ),
                // if (isManager)
                //   ListTile(
                //     leading: const Icon(Icons.fact_check_outlined),
                //     title: const Text('Approve Leave Request'),
                //     onTap: () {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) =>
                //               const ManagerLeaveRequestsPage(),
                //         ),
                //       );
                //     },
                //   ),

                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Purchase Invoice'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CreatePurchaseProductList()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),

                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Purchase Invoice List'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SellerInvoiceListPage()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),

                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Add Supplier'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => add_supplier()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Company'),
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => add_company()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Country'),
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => add_country()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Currency'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => add_currency()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Activit Log'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Activity_log()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Bank Type'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => add_bank_type()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),
                //  ListTile(
                //   leading: Icon(Icons.dashboard),
                //   title: Text('Call Report'),
                //   onTap: () {
                //     Navigator.push(context,
                //         MaterialPageRoute(builder: (context) => CallLog()));
                //   },
                // ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Approve Products'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Approve_products()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Add EMI'),
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => add_Emi()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Asset Management'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AssetManegment()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),

                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Category'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => add_categories()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Bulk Upload Orders'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => UploadBulkProducts()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),

                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Bulk Upload Customers'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => UploadBulkcustomer()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),

                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Add Purpose of payment'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => add_purpose_of_payment()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),
                //   ListTile(
                //   leading: Icon(Icons.person),
                //   title: Text('Bulk Upload'),
                //   onTap: () {
                //     Navigator.push(context,
                //         MaterialPageRoute(builder: (context) => OrderBulkUpload()));
                //     // Navigate to the Settings page or perform any other action
                //   },
                // ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Departments'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => add_department()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Add Rack'),
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => add_rack()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Supervisors'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => add_supervisor()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Division'),
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => add_family()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Bank'),
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => add_bank()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('States'),
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => add_state()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),

                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Warehouse'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => add_warehouse()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Attributes'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => add_attribute()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Attributes'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => add_attribute()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Country code'),
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => add_country()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),

                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Add Daily sales report'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AddDailySalesReport()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),

                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Daily BDO sales report'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DailySalesReportViewPage()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),

                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('All Users sales report'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                AllUsersDailySalesReportPage()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),

                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Categorywise sales report'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CategorywiseSalesReport()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),

                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('All users Categorywise sales report'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                UserwiseCategorywiseSalesReport()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),
                //  ListTile(
                //   leading: Icon(Icons.person),
                //   title: Text('Delivery Notes'),
                //   onTap: () {
                //     Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //             builder: (context) => WarehouseOrderView(status: null,)));
                //     // Navigate to the Settings page or perform any other action
                //   },
                // ),
                Divider(),
                ListTile(
                  // leading: Icon(Icons.skateboarding),
                  title: Text('Family Wise Excel Report'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                CyclingskatingCategoryDailyProductwiseReport()));
                    // Navigate to the Settings page or perform any other action
                  },
                ),

                _buildDropdownTile(
                    context, 'BDO Daily Sales Report', ['BDO Call List']),

                _buildDropdownTile(context, 'Reports', [
                  'Sales Report',
                  'Sales Report Excel',
                  'GST Report',
                  // 'All Division Product Sale Report',
                  // 'Cycling & Skating Monthly Excel',
                  // 'Cycling & Skating Daily Excel',
                  'Tracking Report',
                  'Credit Sales Report',
                  'COD Sales Report',
                  'Statewise Sales Report',
                  'Expence Report',
                  'Delivery Report',
                  'Product Sale Report',
                  'Stock Report',
                  'Damaged Stock',
                  'Finance Report',
                  'Actual Delivery Report',
                ]),

                _buildDropdownTile(context, 'Staff', [
                  'Add Staff',
                  'Staff',
                ]),

                ListTile(
                  title: Text('Employee Leave Form'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EmployeeLeaveFormPage()));
                  },
                ),
                // _buildDropdownTile(context, 'Credit Note', [
                //   'Add Credit Note',
                //   'Credit Note List',
                // ]),

                Divider(),

                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () async {
                    await logoutUser(context);
                  },
                ),
                SizedBox(height: 50),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => EditProfileScreen()),
                        );
                      },
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFFE5E7EB),
                        backgroundImage: getProfileImageUrl().isNotEmpty
                            ? NetworkImage(getProfileImageUrl())
                            : const AssetImage('lib/assets/female.jpeg')
                                as ImageProvider,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      '$username',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 10),

                // Discount/Bonus Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => today_OrderList(
                                        status: null,
                                      )),
                            );
                          },
                          child: _buildInfoCard(totalbills, 'Todays Bills', 0)),
                      GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => OrderList2(
                                        status: "Invoice Created",
                                      )),
                            );
                          },
                          child: _buildInfoCard(
                              approvalcount.toString(), 'Approve Bills', 0)),
                      GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => OrderList2(
                                        status: "Waiting For Confirmation",
                                      )),
                            );
                          },
                          child: _buildInfoCard(
                              confirmcount.toString(), 'Confirm Bills', 0)),
                    ],
                  ),
                ),

                SizedBox(height: 10),

                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                    children: [
                      // Display the count of today's shipped orders
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => today_shipped_OrderList(
                                      status: "Shipped",
                                    )),
                          );
                        },
                        child: _buildGridItem(
                            Icons.local_shipping,
                            'Todays Shipped Orders',
                            todayShippedCount // Pass the length of today's shipped orders
                            ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProformaInvoiceList()),
                          );
                        },
                        child: _buildGridItem(Icons.request_quote,
                            'Proforma Invoice', proforma.length),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => GrvList(
                                      status: null,
                                    )),
                          );
                        },
                        child: _buildGridItem(
                            Icons.receipt_long, 'GRV Created', grvlist.length),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => GrvList(
                                      status: "pending",
                                    )),
                          );
                        },
                        child: _buildGridItem(Icons.pending_actions,
                            'GRV Waiting For Approval', grv),
                      ),
                    ],
                  ),
                ),
              ],
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
