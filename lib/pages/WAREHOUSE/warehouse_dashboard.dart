import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:beposoft/pages/ACCOUNTS/add_self_attendance.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/mailboxpage..dart';
import 'package:beposoft/pages/ACCOUNTS/order_list.dart';
import 'package:beposoft/pages/ADMIN/localpurchaseorderscreen.dart';
import 'package:beposoft/pages/BDO/EmployeeLeaveFormPage%20.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/logout_hekper.dart';
import 'package:intl/intl.dart';
import 'package:beposoft/pages/auth_status_checker.dart';
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

class WarehouseDashboard extends StatefulWidget {
  @override
  State<WarehouseDashboard> createState() => _WarehouseDashboardState();
}

class _WarehouseDashboardState extends State<WarehouseDashboard>
    with WidgetsBindingObserver {
        List<String> statusOptions = ["pending", "approved", "rejected"];
  List<Map<String, dynamic>> grvlist = [];
  List<Map<String, dynamic>> proforma = [];
  List<Map<String, dynamic>> salesReportList = [];
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  List<Map<String, dynamic>> shippedOrders = [];
  int inboxMailCount = 0;
Timer? mailCountTimer;
      String profileImage = '';
        bool isManager = false;

bool isFetchingInboxMailCount = false;
  String? username = '';
@override
void initState() {
  super.initState();

  WidgetsBinding.instance.addObserver(this);

  _getUsername();
  getGrvList();
  fetchproformaData();
  getSalesReport();
  fetchOrderData();
  fetchInboxMailCount();
  getProfile();

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

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    checkAppUpdate(context);
  });
}
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  super.didChangeAppLifecycleState(state);

  if (state == AppLifecycleState.resumed) {
    fetchInboxMailCount();
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

  int toprint = 0;
  int packed = 0;
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
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  mailCountTimer?.cancel();
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
        var productsData = parsed;
        List<Map<String, dynamic>> orderList = [];

        for (var productData in productsData) {
          String rawOrderDate = productData['order_date'];
          String formattedOrderDate = rawOrderDate;

          try {
            DateTime parsedOrderDate =
                DateFormat('yyyy-MM-dd').parse(rawOrderDate);
            formattedOrderDate = DateFormat('yyyy-MM-dd')
                .format(parsedOrderDate); // Convert to desired format
          } catch (e) {}

          // Add to orderList if status is "Shipped" or "To "

          orderList.add({
            'id': productData['id'],
            'invoice': productData['invoice'],
            'manage_staff': productData['manage_staff'],
            'customer': {
              'name': productData['customer']['name'],
              'phone': productData['customer']['phone'],
              'email': productData['customer']['email'],
              'address': productData['customer']['address'],
            },
            'billing_address': {
              'name': productData['billing_address']['name'],
              'email': productData['billing_address']['email'],
              'zipcode': productData['billing_address']['zipcode'],
              'address': productData['billing_address']['address'],
              'phone': productData['billing_address']['phone'],
              'city': productData['billing_address']['city'],
              'state': productData['billing_address']['state'],
            },
            'bank': {
              'name': productData['bank']['name'],
              'account_number': productData['bank']['account_number'],
              'ifsc_code': productData['bank']['ifsc_code'],
              'branch': productData['bank']['branch'],
            },
            'items': productData['items'] != null
                ? productData['items'].map((item) {
                    return {
                      'id': item['id'],
                      'name': item['name'],
                      'quantity': item['quantity'],
                      'price': item['price'],
                      'tax': item['tax'],
                      'discount': item['discount'],
                      'images': item['images'],
                    };
                  }).toList()
                : [],
            'status': productData['status'],
            'total_amount': productData['total_amount'],
            'order_date': formattedOrderDate, // Use the formatted string
          });
          if (productData['status'] == 'To Print') {
            toprint++;
          } else if (productData['status'] == 'Packed') {
            packed++;
          }
        }

        setState(() {
          orders = orderList;

          filteredOrders = orderList;
        });
      }
    } catch (error) {}
  }

  Future<void> getSalesReport() async {
    setState(() {});
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/salesreport'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var salesData = parsed['Sales report'];

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
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to fetch sales report data'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error fetching sales report data'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {});
    }
  }

  String getTodaysBills() {
    // Get today's date in the same format as in the response (yyyy-MM-dd)
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Find today's report entry
    var todaysReport = salesReportList.firstWhere(
      (report) => report['date'] == currentDate,
      orElse: () => {}, // Return null if no report for today
    );

    if (todaysReport['total_bills_in_date'] != null) {
      return todaysReport['total_bills_in_date'].toString();
    } else {
      return '0'; // Return '0' if no report is found for today
    }
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

// Function to fetch GRV data
  Future<void> getGrvList() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/grvget/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

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
        }
        setState(() {
          grvlist = grvDataList;
        });

        // Get the count of grvlist
        int grvListCount = grvlist.length;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to fetch GRV data'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error fetching GRV data'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<String?> getusernameFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  // Retrieve the username from SharedPreferences
  Future<void> _getUsername() async {
    final name = await getusernameFromPrefs();
    setState(() {
      username = name ?? 'Guest'; // Default to 'Guest' if no username
    });
  }

  void logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.remove('userId');
    // await prefs.remove('token');
    // await prefs.remove('username');
    // await prefs.remove('department');
    // await prefs.remove('warehouse');
    await Future.delayed(Duration(milliseconds: 100));
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
                inboxMailCount > 99 ? '99+' : inboxMailCount.toString(),
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
                ListTile(
                  leading: Icon(Icons.dashboard),
                  title: Text('Dashboard'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => WarehouseDashboard()));
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
   _buildDropdownTile(context, 'Purchase', [
                    'Product List',
                    // 'Purchase request',
                    // 'Purchase request List',
                    'Product Add',
                  ]),
            
                Divider(),
                _buildDropdownTile(context, 'Delivery Note', [
                  'Delivery Note List(All)',
                  'Delivery Note List(To Print)',
                  'Delivery Note List(Packing under Progress)',
                  'Delivery Note List(Packed)',
                  'Delivery Note List(Ready to ship)',
                  'Delivery Note List(Shipped)',
                  'Daily Goods Movement'
                ]),
                _buildDropdownTile(
                    context, 'GRV', ['Create New GRV', 'GRVs List']),
                Divider(),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Employee Leave Form'),
                  onTap: () async {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EmployeeLeaveFormPage()));
                  },
                ),
                Divider(),
                    _buildDropdownTile(context, 'Reports', [
                    // 'Sales Report',
                    // 'Sales Report Excel',
                    // 'GST Report',
                    'Product Stock Report',
                    // 'Order Items Excel Report',
                    // 'Shipping Address Excel Report',
                    // 'Daily Product Sold Report',
                    // 'All Division Product Sale Report',
                    // 'Cycling & Skating Monthly Excel',
                    // 'Cycling & Skating Daily Excel',
                    // 'Tracking Report',
                    // 'Credit Sales Report',
                    // 'COD Sales Report',
                    // 'Statewise Sales Report',
                    // 'Expence Report',
                    // 'Delivery Report',
                    'Product Sale Report',
                    'Stock Report',
                    'Damaged Stock',
                    // 'Finance Report',
                    // 'Actual Delivery Report',
                    // 'Order Comparison Report',
                  ]),

                         ListTile(
                    leading: Icon(Icons.dashboard),
                    title: Text('Local Purchase Order'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  LocalPurchaseOrderScreen()));
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () async {
                    await logoutUser(context);
                  },
                ),
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
                            builder: (context) => EditProfileScreen(),
                          ),
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

                Expanded(
                  child: ListView(
                    children: [
                      // Display the count of today's shipped orders in cards
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => WarehouseOrderView(
                                      status: 'To Print',
                                    )),
                          );
                        },
                        child: _buildCard(Icons.local_shipping,
                            'Waiting For Packing  ', toprint),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    WarehouseOrderView(status: 'Packed')),
                          );
                        },
                        child: _buildCard(Icons.request_quote,
                            'Waiting For Shipping', packed),
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

  Widget _buildCard(IconData icon, String title, [int count = 0]) {
    return Container(
      height: 120.0, // Set a fixed height for each card
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: 20,
                ),
                ListTile(
                  leading: Icon(icon, size: 40, color: Colors.blue),
                  title: Text(title,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    // Handle item tap if needed
                  },
                ),
              ],
            ),
            if (count > 0)
              Positioned(
                top: 8.0,
                right: 8.0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
