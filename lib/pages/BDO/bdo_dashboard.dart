import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:beposoft/pages/ACCOUNTS/add_district.dart';
import 'package:beposoft/pages/ACCOUNTS/add_self_attendance.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
// import 'package:beposoft/pages/ACCOUNTS/call_log.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/mailboxpage..dart';
import 'package:beposoft/pages/ACCOUNTS/order_list.dart';
import 'package:beposoft/pages/ADMIN/localpurchaseorderscreen.dart';
import 'package:beposoft/pages/BDO/EmployeeLeaveFormPage%20.dart';
import 'package:beposoft/pages/BDO/add_district.dart';
import 'package:beposoft/pages/BDO/bdo_customer_list.dart';
import 'package:beposoft/pages/BDO/bdo_order_list.dart';
import 'package:beposoft/pages/BDO/categorywise_sales_report.dart';
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

class bdo_dashbord extends StatefulWidget {
  @override
  State<bdo_dashbord> createState() => _bdo_dashbordState();
}

class _bdo_dashbordState extends State<bdo_dashbord>
    with WidgetsBindingObserver {
  List<String> statusOptions = ["pending", "approved", "rejected"];
  List<Map<String, dynamic>> grvlist = [];
  List<Map<String, dynamic>> proforma = [];
  List<Map<String, dynamic>> salesReportList = [];
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  List<Map<String, dynamic>> shippedOrders = [];
  int customers = 0;
  bool isFetchingInboxMailCount = false;
  List<Map<String, dynamic>> customer = [];
  List<Map<String, dynamic>> filteredProducts = [];
  int inboxMailCount = 0;
  Timer? mailCountTimer;
  String? username = '';
  String profileImage = '';
  bool isManager = false;

  int myTotalBills = 0;
  double myTotalAmount = 0.0;
  int myInvoiceCreatedBills = 0;
  int myTodaysBills = 0;
  double myTodaysTotalAmount = 0.0;
  bool isMyOrderSummaryLoading = false;

  // ============================================================
  // CALL DURATION SUMMARY
  // API: GET /api/sales/team/member/daily/report/add/
  // ============================================================

  int todayActiveCallCount = 0;
  int todayProductiveCallCount = 0;
  double averageCallDurationPercent = 0.0;
  bool isCallDurationSummaryLoading = false;

  // ============================================================
  // BOTTOM NAVIGATION + DASHBOARD SEARCH
  // ============================================================

  bool isBottomSearchOpen = false;
  String dashboardSearchQuery = '';

  final TextEditingController dashboardSearchController =
      TextEditingController();

  final FocusNode dashboardSearchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getUsername(); // Get the username when the page loads
    getGrvList();
    fetchproformaData();
    getSalesReport();
    fetchOrderData();
    getcustomer();
    fetchInboxMailCount();
    getProfile();
    fetchMyOrderSummary();
    fetchCallDurationSummary();

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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    mailCountTimer?.cancel();
    dashboardSearchController.dispose();
    dashboardSearchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      fetchInboxMailCount();
      fetchMyOrderSummary();
      fetchCallDurationSummary();
    }
  }

  Future<void> fetchMyOrderSummary() async {
    if (!mounted) return;

    setState(() {
      isMyOrderSummaryLoading = true;
    });

    try {
      final String? token = await getTokenFromPrefs();

      if (token == null || token.trim().isEmpty) {
        if (!mounted) return;

        setState(() {
          myTotalBills = 0;
          myTotalAmount = 0.0;
          myInvoiceCreatedBills = 0;
          myTodaysBills = 0;
          myTodaysTotalAmount = 0.0;
        });

        return;
      }

      final http.Response response = await http.get(
        Uri.parse(
          '$api/api/my/order/summary/',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
        'MY ORDER SUMMARY RESPONSE: ${response.statusCode}',
      );

      debugPrint(
        'MY ORDER SUMMARY BODY: ${response.body}',
      );

      if (response.statusCode == 200) {
        final dynamic parsed = jsonDecode(
          response.body,
        );

        if (parsed is Map<String, dynamic> &&
            parsed['status'] == 'success') {
          final Map<String, dynamic> allOrders =
              parsed['all_orders'] is Map
                  ? Map<String, dynamic>.from(
                      parsed['all_orders'],
                    )
                  : <String, dynamic>{};

          final Map<String, dynamic> todayOrders =
              parsed['today_orders'] is Map
                  ? Map<String, dynamic>.from(
                      parsed['today_orders'],
                    )
                  : <String, dynamic>{};

          final Map<String, dynamic> invoiceCreated =
              parsed['invoice_created'] is Map
                  ? Map<String, dynamic>.from(
                      parsed['invoice_created'],
                    )
                  : <String, dynamic>{};

          if (!mounted) return;

          setState(() {
            myTotalBills = int.tryParse(
                  allOrders['count']?.toString() ?? '0',
                ) ??
                0;

            myTotalAmount = double.tryParse(
                  allOrders['total_amount']?.toString() ?? '0',
                ) ??
                0.0;

            myInvoiceCreatedBills = int.tryParse(
                  invoiceCreated['count']?.toString() ?? '0',
                ) ??
                0;

            myTodaysBills = int.tryParse(
                  todayOrders['count']?.toString() ?? '0',
                ) ??
                0;

            myTodaysTotalAmount = double.tryParse(
                  todayOrders['total_amount']?.toString() ?? '0',
                ) ??
                0.0;
          });
        } else {
          if (!mounted) return;

          setState(() {
            myTotalBills = 0;
            myTotalAmount = 0.0;
            myInvoiceCreatedBills = 0;
            myTodaysBills = 0;
            myTodaysTotalAmount = 0.0;
          });
        }
      } else {
        debugPrint(
          'Failed to fetch my order summary: ${response.statusCode}',
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'MY ORDER SUMMARY ERROR: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() {
          isMyOrderSummaryLoading = false;
        });
      }
    }
  }


  Future<void> fetchCallDurationSummary() async {
    if (!mounted) return;

    setState(() {
      isCallDurationSummaryLoading = true;
    });

    try {
      final String? token = await getTokenFromPrefs();

      if (token == null || token.trim().isEmpty) {
        if (!mounted) return;

        setState(() {
          todayActiveCallCount = 0;
          todayProductiveCallCount = 0;
          averageCallDurationPercent = 0.0;
        });

        return;
      }

      final DateTime now = DateTime.now();
      final String today = DateFormat('yyyy-MM-dd').format(now);

      final Uri uri = Uri.parse(
        '$api/api/sales/team/member/daily/report/add/',
      ).replace(
        queryParameters: {
          'start_date': today,
          'end_date': today,
          'page': '1',
          'page_size': '1',
        },
      );

      final http.Response response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
        'CALL DURATION SUMMARY RESPONSE: ${response.statusCode}',
      );

      debugPrint(
        'CALL DURATION SUMMARY BODY: ${response.body}',
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(
          response.body,
        );

        if (decoded is Map<String, dynamic>) {
          final dynamic results = decoded['results'];

          if (results is Map) {
            final Map<String, dynamic> summary =
                Map<String, dynamic>.from(
              results['summary'] is Map
                  ? results['summary']
                  : <String, dynamic>{},
            );

            final int activeCount = int.tryParse(
                  summary['active_count']?.toString() ?? '0',
                ) ??
                0;

            final int productiveCount = int.tryParse(
                  summary['productive_count']?.toString() ?? '0',
                ) ??
                0;

            final double avgValue = double.tryParse(
                  summary['call_duration_average_8hrs']?.toString() ?? '0',
                ) ??
                0.0;

            if (!mounted) return;

            setState(() {
              todayActiveCallCount = activeCount;
              todayProductiveCallCount = productiveCount;

              // The API field is used directly as the percentage value.
              averageCallDurationPercent = avgValue;
            });

            return;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        todayActiveCallCount = 0;
        todayProductiveCallCount = 0;
        averageCallDurationPercent = 0.0;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'CALL DURATION SUMMARY ERROR: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        todayActiveCallCount = 0;
        todayProductiveCallCount = 0;
        averageCallDurationPercent = 0.0;
      });
    } finally {
      if (mounted) {
        setState(() {
          isCallDurationSummaryLoading = false;
        });
      }
    }
  }

  String formatCompactAmount(dynamic value) {
    double amount = 0.0;

    if (value is int) {
      amount = value.toDouble();
    } else if (value is double) {
      amount = value;
    } else {
      amount = double.tryParse(value.toString()) ?? 0.0;
    }

    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)} K';
    } else {
      return amount.toStringAsFixed(2);
    }
  }

  Widget _buildInfoCard(
    String value,
    String label,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMyOrderSummaryCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  isMyOrderSummaryLoading
                      ? '...'
                      : myTotalBills.toString(),
                  'Total Bills',
                ),
              ),
              const SizedBox(
                width: 6,
              ),
              Expanded(
                child: _buildInfoCard(
                  isMyOrderSummaryLoading
                      ? '...'
                      : formatCompactAmount(
                          myTotalAmount,
                        ),
                  'Total Volume',
                ),
              ),
              const SizedBox(
                width: 6,
              ),
              Expanded(
                child: _buildInfoCard(
                  isMyOrderSummaryLoading
                      ? '...'
                      : myInvoiceCreatedBills
                          .toString(),
                  'Waiting For Approval',
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  isMyOrderSummaryLoading
                      ? '...'
                      : myTodaysBills.toString(),
                  'Today Bills',
                ),
              ),
              const SizedBox(
                width: 6,
              ),
              Expanded(
                child: _buildInfoCard(
                  isMyOrderSummaryLoading
                      ? '...'
                      : formatCompactAmount(
                          myTodaysTotalAmount,
                        ),
                  'Today Volume',
                ),
              ),
              const SizedBox(
                width: 6,
              ),
              const Expanded(
                child: SizedBox(),
              ),
            ],
          ),
        ],
      ),
    );
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

        final dynamic rawUnreadCount = decoded['unread_count'] ??
            (results is Map ? results['unread_count'] : null) ??
            (data is Map ? data['unread_count'] : null);

        final dynamic rawFilteredCount = decoded['count'] ??
            (results is Map ? results['count'] : null) ??
            (data is Map ? data['count'] : null);

        if (rawUnreadCount != null) {
          newUnreadCount = rawUnreadCount is int
              ? rawUnreadCount
              : int.tryParse(rawUnreadCount.toString()) ?? 0;
        } else if (rawFilteredCount != null) {
          newUnreadCount = rawFilteredCount is int
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

              return readAt == null || readAt.toString().trim().isEmpty;
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

  int toprint = 0;
  int packed = 0;
  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
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

  Future<void> getcustomer() async {
    try {
      // final dep = await getdepFromPrefs();

      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/staff/customers/'),
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
        List<Map<String, dynamic>> managerlist = [];

        for (var productData in productsData) {
          managerlist.add({
            'id': productData['id'],
            'name': productData['name'],
            'created_at': productData['created_at']
          });
        }

        setState(() {
          customer = managerlist; // Update full customer list
          filteredProducts =
              List.from(customer); // Show all customers initially
        });
      }
    } catch (error) {
      ;
    }
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

          // Add to orderList if status is "Shipped" or "To print"

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
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('Failed to fetch sales report data'),
        //     duration: Duration(seconds: 2),
        //   ),
        // );
      }
    } catch (error) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('Error fetching sales report data'),
      //     duration: Duration(seconds: 2),
      //   ),
      // );
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
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('Failed to fetch GRV data'),
        //     duration: Duration(seconds: 2),
        //   ),
        // );
      }
    } catch (error) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('Error fetching GRV data'),
      //     duration: Duration(seconds: 2),
      //   ),
      // );
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
            d.navigateToSelectedPage2(context, option);
          },
        );
      }).toList(),
    );
  }


  // ============================================================
  // BDO DASHBOARD GRID MENU
  // Drawer items are also shown as cards below the top summary card.
  // ============================================================

  List<Map<String, dynamic>> _getBdoFrontMenuItems() {
    return [
      {
        'title': 'DSR (Daily Sales Report)',
        'icon': Icons.bar_chart_rounded,
        'groupType': 'dsrSummary',
        'keywords':
            'dsr daily sales report today bills total bills today volume total volume',
      },
      {
        'title': 'CD Call Duration',
        'icon': Icons.call_outlined,
        'groupType': 'callDurationSummary',
        'keywords':
            'cd call duration active call productive call average call duration',
      },
      {
        'title': 'Add Attendance',
        'icon': Icons.person_outline_rounded,
        'keywords': 'attendance add attendance',
      },
      {
        'title': 'Customers',
        'icon': Icons.people_alt_outlined,
        'groupType': 'customers',
        'keywords': 'customers add new customers view customers',
      },
      {
        'title': 'Proforma Invoice',
        'icon': Icons.description_outlined,
        'groupType': 'proforma',
        'keywords':
            'proforma invoice create proforma invoice view proforma invoice',
      },
      {
        'title': 'Orders',
        'icon': Icons.receipt_long_outlined,
        'groupType': 'orders',
        'keywords': 'orders view order list',
      },
      {
        'title': 'Local Purchase Order',
        'icon': Icons.shopping_cart_checkout_rounded,
        'keywords': 'local purchase order lpo',
      },
      {
        'title': 'Create DSR',
        'icon': Icons.analytics_outlined,
        'groupType': 'dsr',
        'keywords':
            'create dsr bdo add dsr view dsr list call duration add district',
      },
    ];
  }

  List<Map<String, dynamic>> _getBdoGroupItems(String groupType) {
    switch (groupType) {
      case 'customers':
        return [
          {
            'title': 'Add New Customers',
            'icon': Icons.person_add_alt_1_outlined,
          },
          {
            'title': 'View Customers',
            'icon': Icons.people_outline_rounded,
          },
        ];

      case 'proforma':
        return [
          {
            'title': 'Create Proforma Invoice',
            'icon': Icons.note_add_outlined,
          },
          {
            'title': 'View Proforma Invoice',
            'icon': Icons.description_outlined,
          },
        ];

      case 'orders':
        return [
          {
            'title': 'View Order List',
            'icon': Icons.list_alt_rounded,
          },
        ];

      case 'dsr':
        return [
          {
            'title': 'BDO ADD DSR',
            'icon': Icons.add_chart_rounded,
          },
          {
            'title': 'VIEW DSR LIST',
            'icon': Icons.view_list_rounded,
          },
          {
            'title': 'BDO ADD CALL DURATION',
            'icon': Icons.add_ic_call_outlined,
          },
          {
            'title': 'VIEW CALL DURATION LIST',
            'icon': Icons.call_outlined,
          },
          {
            'title': 'Add District',
            'icon': Icons.location_city_outlined,
          },
        ];

      default:
        return [];
    }
  }

  Future<void> _navigateFromFrontCard(String item) async {
    switch (item) {
      case 'Dashboard':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => bdo_dashbord(),
          ),
        );
        return;

      case 'Add Attendance':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StaffSelfAttendanceScreen(),
          ),
        );
        return;

      case 'Send Mail':
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => const StaffMailPage(),
          ),
        );

        if (!mounted) return;

        await fetchInboxMailCount();
        return;

      case 'Local Purchase Order':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LocalPurchaseOrderScreen(),
          ),
        );
        return;

      case 'Add District':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddDistricts(),
          ),
        );
        return;

      case 'Employee Leave Form':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmployeeLeaveFormPage(),
          ),
        );
        return;

      case 'Logout':
        await logoutUser(context);
        return;

      default:
        d.navigateToSelectedPage2(
          context,
          item,
        );
        return;
    }
  }


  // ============================================================
  // DSR SUMMARY CARD
  // DATA SOURCE: GET $api/api/my/order/summary/
  // ============================================================


  // ============================================================
  // CD CALL DURATION CARD
  // DATA SOURCE: GET /api/sales/team/member/daily/report/add/
  // FILTERED TO TODAY
  // ============================================================

  Widget _buildCallDurationSummaryCard({
    required bool isVerySmallPhone,
  }) {
    Widget buildMetricRow({
      required String label,
      required String value,
    }) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isVerySmallPhone ? 8 : 10,
          vertical: isVerySmallPhone ? 8 : 9,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.13),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.24),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: isVerySmallPhone ? 9 : 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isVerySmallPhone ? 13 : 15,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    String formattedAverage = '0%';

    if (!isCallDurationSummaryLoading) {
      final double value = averageCallDurationPercent;

      formattedAverage = value % 1 == 0
          ? '${value.toStringAsFixed(0)}%'
          : '${value.toStringAsFixed(1)}%';
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF56AFFF),
            Color(0xFF2C74FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C74FF).withOpacity(0.28),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isVerySmallPhone ? 9 : 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'CD Call Duration',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isVerySmallPhone ? 10.5 : 12,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: isVerySmallPhone ? 30 : 32,
                  height: isVerySmallPhone ? 30 : 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.22),
                    ),
                  ),
                  child: Icon(
                    Icons.call_outlined,
                    color: Colors.white,
                    size: isVerySmallPhone ? 17 : 18,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  buildMetricRow(
                    label: 'Today Active Call',
                    value: isCallDurationSummaryLoading
                        ? '...'
                        : todayActiveCallCount.toString(),
                  ),
                  const SizedBox(height: 6),
                  buildMetricRow(
                    label: 'Today Productive Call',
                    value: isCallDurationSummaryLoading
                        ? '...'
                        : todayProductiveCallCount.toString(),
                  ),
                  const SizedBox(height: 6),
                  buildMetricRow(
                    label: 'Avg Call Duration',
                    value: isCallDurationSummaryLoading
                        ? '...'
                        : formattedAverage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDsrSummaryCard({
    required bool isVerySmallPhone,
  }) {
    Widget buildMetricRow({
      required String label,
      required String value,
    }) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isVerySmallPhone ? 8 : 10,
          vertical: isVerySmallPhone ? 6 : 7,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.13),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.24),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: isVerySmallPhone ? 9 : 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isVerySmallPhone ? 13 : 15,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF56AFFF),
            Color(0xFF2C74FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C74FF).withOpacity(0.28),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isVerySmallPhone ? 9 : 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'DSR (Daily Sales Report)',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isVerySmallPhone ? 10.5 : 12,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: isVerySmallPhone ? 30 : 32,
                  height: isVerySmallPhone ? 30 : 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.22),
                    ),
                  ),
                  child: Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.white,
                    size: isVerySmallPhone ? 17 : 18,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildMetricRow(
                    label: 'Today Bills',
                    value: isMyOrderSummaryLoading
                        ? '...'
                        : myTodaysBills.toString(),
                  ),
                  buildMetricRow(
                    label: 'Total Bills',
                    value: isMyOrderSummaryLoading
                        ? '...'
                        : myTotalBills.toString(),
                  ),
                  buildMetricRow(
                    label: 'Today Volume',
                    value: isMyOrderSummaryLoading
                        ? '...'
                        : formatCompactAmount(
                            myTodaysTotalAmount,
                          ),
                  ),
                  buildMetricRow(
                    label: 'Total Volume',
                    value: isMyOrderSummaryLoading
                        ? '...'
                        : formatCompactAmount(
                            myTotalAmount,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrontMenuCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF56AFFF),
                Color(0xFF2C74FF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2C74FF).withOpacity(0.28),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.22),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      'Open',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.90),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white.withOpacity(0.92),
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedMenuCard({
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required bool isVerySmallPhone,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF56AFFF),
            Color(0xFF2C74FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C74FF).withOpacity(0.28),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isVerySmallPhone ? 10 : 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isVerySmallPhone ? 11.5 : 13,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: isVerySmallPhone ? 32 : 34,
                  height: isVerySmallPhone ? 32 : 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.22),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isVerySmallPhone ? 18 : 19,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (
                  BuildContext context,
                  int index,
                ) {
                  return const SizedBox(height: 4);
                },
                itemBuilder: (
                  BuildContext context,
                  int index,
                ) {
                  final Map<String, dynamic> menuItem = items[index];

                  final String itemTitle =
                      menuItem['title']?.toString() ?? '';

                  final IconData itemIcon =
                      menuItem['icon'] as IconData;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: () {
                        _navigateFromFrontCard(itemTitle);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: isVerySmallPhone ? 6 : 7,
                          vertical: isVerySmallPhone ? 5 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.11),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              itemIcon,
                              color: Colors.white,
                              size: isVerySmallPhone ? 13 : 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                itemTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      isVerySmallPhone ? 8.5 : 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white.withOpacity(0.90),
                              size: 15,
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
  }

  Widget _buildFrontMenuSection() {
    final List<Map<String, dynamic>> items = _getBdoFrontMenuItems();

    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final bool isVerySmallPhone = constraints.maxWidth < 340;

        final double horizontalSpacing =
            isVerySmallPhone ? 8 : 12;

        final double verticalSpacing =
            isVerySmallPhone ? 8 : 12;

        final double cardHeight =
            isVerySmallPhone ? 195 : 210;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: horizontalSpacing,
            mainAxisSpacing: verticalSpacing,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (
            BuildContext context,
            int index,
          ) {
            final Map<String, dynamic> item = items[index];

            final String itemTitle =
                item['title']?.toString() ?? '';

            final IconData itemIcon =
                item['icon'] as IconData;

            final String? groupType =
                item['groupType']?.toString();

            if (groupType != null && groupType.isNotEmpty) {
              if (groupType == 'dsrSummary') {
                return _buildDsrSummaryCard(
                  isVerySmallPhone: isVerySmallPhone,
                );
              }

              if (groupType == 'callDurationSummary') {
                return _buildCallDurationSummaryCard(
                  isVerySmallPhone: isVerySmallPhone,
                );
              }

              return _buildGroupedMenuCard(
                title: itemTitle,
                icon: itemIcon,
                items: _getBdoGroupItems(groupType),
                isVerySmallPhone: isVerySmallPhone,
              );
            }

            return _buildFrontMenuCard(
              title: itemTitle,
              icon: itemIcon,
              onTap: () {
                _navigateFromFrontCard(itemTitle);
              },
            );
          },
        );
      },
    );
  }


  // ============================================================
  // DASHBOARD SEARCH
  // ============================================================

  Widget _buildDashboardSearchResults() {
    final String query = dashboardSearchQuery.trim().toLowerCase();

    final List<Map<String, dynamic>> matchedItems =
        _getBdoFrontMenuItems().where(
      (Map<String, dynamic> item) {
        final String title =
            item['title']?.toString().toLowerCase() ?? '';

        final String keywords =
            item['keywords']?.toString().toLowerCase() ?? '';

        return title.contains(query) || keywords.contains(query);
      },
    ).toList();

    if (matchedItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 52,
          horizontal: 24,
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: Color(0xFF8E8E93),
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No cards found',
              style: TextStyle(
                color: Color(0xFF1C1C1E),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different search',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final bool isVerySmallPhone = constraints.maxWidth < 340;

        final double horizontalSpacing =
            isVerySmallPhone ? 8 : 12;

        final double verticalSpacing =
            isVerySmallPhone ? 8 : 12;

        final double cardHeight =
            isVerySmallPhone ? 195 : 210;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: matchedItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: horizontalSpacing,
            mainAxisSpacing: verticalSpacing,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (
            BuildContext context,
            int index,
          ) {
            final Map<String, dynamic> item = matchedItems[index];

            final String itemTitle =
                item['title']?.toString() ?? '';

            final IconData itemIcon =
                item['icon'] as IconData;

            final String? groupType =
                item['groupType']?.toString();

            if (groupType != null && groupType.isNotEmpty) {
              if (groupType == 'dsrSummary') {
                return _buildDsrSummaryCard(
                  isVerySmallPhone: isVerySmallPhone,
                );
              }

              if (groupType == 'callDurationSummary') {
                return _buildCallDurationSummaryCard(
                  isVerySmallPhone: isVerySmallPhone,
                );
              }

              return _buildGroupedMenuCard(
                title: itemTitle,
                icon: itemIcon,
                items: _getBdoGroupItems(groupType),
                isVerySmallPhone: isVerySmallPhone,
              );
            }

            return _buildFrontMenuCard(
              title: itemTitle,
              icon: itemIcon,
              onTap: () {
                _navigateFromFrontCard(itemTitle);
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION ACTIONS
  // ============================================================

  void _toggleBottomSearch() {
    final bool shouldOpen = !isBottomSearchOpen;

    setState(() {
      isBottomSearchOpen = shouldOpen;

      if (!shouldOpen) {
        dashboardSearchQuery = '';
        dashboardSearchController.clear();
      }
    });

    if (shouldOpen) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (!mounted) return;
          dashboardSearchFocusNode.requestFocus();
        },
      );
    } else {
      dashboardSearchFocusNode.unfocus();
    }
  }

  void _closeBottomSearch() {
    if (!isBottomSearchOpen &&
        dashboardSearchController.text.isEmpty &&
        dashboardSearchQuery.isEmpty) {
      return;
    }

    dashboardSearchFocusNode.unfocus();

    setState(() {
      isBottomSearchOpen = false;
      dashboardSearchQuery = '';
      dashboardSearchController.clear();
    });
  }

  Future<void> _openBottomMail() async {
    _closeBottomSearch();

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => const StaffMailPage(),
      ),
    );

    if (!mounted) return;

    await fetchInboxMailCount();
  }

  void _openBottomProfile() {
    _closeBottomSearch();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(),
      ),
    );
  }

  void _openBottomApproval() {
    _closeBottomSearch();

    d.navigateToSelectedPage2(
      context,
      'View Proforma Invoice',
    );
  }

  // ============================================================
  // MODERN BOTTOM NAVIGATION
  // SAME DESIGN AS WAREHOUSE DASHBOARD
  // ============================================================

  Widget _buildModernBottomNavigationBar() {
    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: Material(
        color: Colors.white,
        elevation: 14,
        shadowColor: Colors.black.withOpacity(0.10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 68,
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 7,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(26),
                  topRight: Radius.circular(26),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildBottomNavigationItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                      isSelected: false,
                      onTap: _openBottomProfile,
                    ),
                  ),
                  Expanded(
                    child: _buildBottomNavigationItem(
                      icon: Icons.mail_outline_rounded,
                      label: 'Mail',
                      isSelected: false,
                      badgeCount: inboxMailCount,
                      onTap: () {
                        _openBottomMail();
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildBottomNavigationItem(
                      icon: Icons.search_rounded,
                      label: 'Search',
                      isSelected: isBottomSearchOpen,
                      onTap: _toggleBottomSearch,
                    ),
                  ),
                  // Expanded(
                  //   child: _buildBottomNavigationItem(
                  //     icon: Icons.verified_outlined,
                  //     label: 'Approval',
                  //     isSelected: false,
                  //     onTap: _openBottomApproval,
                  //   ),
                  // ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: isBottomSearchOpen
                  ? Padding(
                      key: const ValueKey<String>(
                        'dashboard-search-open',
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        9,
                        12,
                        4,
                      ),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE5E5EA),
                          ),
                        ),
                        child: TextField(
                          controller: dashboardSearchController,
                          focusNode: dashboardSearchFocusNode,
                          textInputAction: TextInputAction.search,
                          autocorrect: false,
                          enableSuggestions: false,
                          onChanged: (String value) {
                            setState(() {
                              dashboardSearchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search cards',
                            hintStyle: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF8E8E93),
                              size: 22,
                            ),
                            suffixIcon: dashboardSearchQuery.isNotEmpty
                                ? IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      dashboardSearchController.clear();

                                      setState(() {
                                        dashboardSearchQuery = '';
                                      });

                                      dashboardSearchFocusNode.requestFocus();
                                    },
                                    icon: const Icon(
                                      Icons.cancel_rounded,
                                      color: Color(0xFF8E8E93),
                                      size: 20,
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(
                      key: ValueKey<String>(
                        'dashboard-search-closed',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    final Color foregroundColor = isSelected
        ? const Color(0xFF2C74FF)
        : const Color(0xFF6B7280);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          height: 54,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 36,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEAF2FF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: foregroundColor,
                      size: 23,
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -7,
                      top: -5,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          badgeCount > 99
                              ? '99+'
                              : badgeCount.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 10.5,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
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
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                tooltip: 'Logout',
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Colors.black,
                  size: 27,
                ),
                onPressed: () async {
                  await logoutUser(context);
                },
              ),
            ),
          ],
        ),
//         drawer: Drawer(
//           backgroundColor: Colors.white,
//           child: Container(
//             color: Colors.white,
//             child: ListView(
//               padding: EdgeInsets.zero,
//               children: <Widget>[
//                 DrawerHeader(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(18),
//                         child: Image.asset(
//                           "lib/assets/appstore.png",
//                           width: 90,
//                           height: 90,
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 ListTile(
//                   leading: Icon(Icons.dashboard),
//                   title: Text('Dashboard'),
//                   onTap: () {
//                     Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => bdo_dashbord()));
//                   },
//                 ),
//                 // ListTile(
//                 //   leading: Icon(Icons.dashboard),
//                 //   title: Text('Call Report'),
//                 //   onTap: () {
//                 //     Navigator.push(context,
//                 //         MaterialPageRoute(builder: (context) => CallLog()));
//                 //   },
//                 // ),
//                 ListTile(
//                   leading: Icon(Icons.person),
//                   title: Text('Add Attendance'),
//                   onTap: () {
//                     Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => StaffSelfAttendanceScreen()));
//                     // Navigate to the Settings page or perform any other action
//                   },
//                 ),
//                 ListTile(
//                   title: const Text('Send Mail'),
//                   onTap: () async {
//                     Navigator.pop(context);

//                     await Navigator.push<void>(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const StaffMailPage(),
//                       ),
//                     );

//                     if (!mounted) return;

//                     await fetchInboxMailCount();
//                   },
//                 ),

//                 Divider(),
//                 _buildDropdownTile(context, 'Customers', [
//                   'Add New Customers',
//                   'View Customers',
//                 ]),

//                 _buildDropdownTile(context, 'Proforma Invoice', [
//                   'Create Proforma Invoice',
//                   'View Proforma Invoice',
//                 ]),
//                 _buildDropdownTile(context, 'Orders', [
//                   // 'Create Orders',
//                   'View Order List'
//                 ]),

//                 ListTile(
//                   leading: Icon(Icons.dashboard),
//                   title: Text('Local Purchase Order'),
//                   onTap: () {
//                     Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => LocalPurchaseOrderScreen()));
//                   },
//                 ),

//                 ListTile(
//                   title: Text('Add District'),
//                   onTap: () {
//                     Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => AddDistricts()));
//                   },
//                 ),

//                 ListTile(
//                   title: Text('Employee Leave Form'),
//                   onTap: () {
//                     Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => EmployeeLeaveFormPage()));
//                   },
//                 ),

//                 // _buildDropdownTile(context, 'Daily Sales Report (DSR)',
//                 //     ['Add Daily Sales', 'DSR List']),

//                 // _buildDropdownTile(context, 'Daily Sales Report (DSR)',
//                 //     ['Add DSR', 'View Sales Report List']),

//                 _buildDropdownTile(context, 'Create DSR', [
//                   'BDO ADD DSR',
//                   'VIEW DSR LIST',
//                   'BDO ADD CALL DURATION',
//                   'VIEW CALL DURATION LIST'
//                 ]),

//                 // ListTile(
//                 //   title: Text('Categorywise Sales Report'),
//                 //   onTap: () {
//                 //     Navigator.push(
//                 //         context,
//                 //         MaterialPageRoute(
//                 //             builder: (context) => BDOCategorywiseSalesReport()));
//                 //   },
//                 // ),

//                 Divider(),
//                 ListTile(
//                   leading: const Icon(Icons.logout),
//                   title: const Text('Logout'),
//                   onTap: () async {
//                     await logoutUser(context);
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
        bottomNavigationBar: _buildModernBottomNavigationBar(),

        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '$username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                buildMyOrderSummaryCard(),

                const SizedBox(height: 14),

                if (isBottomSearchOpen &&
                    dashboardSearchQuery.trim().isNotEmpty)
                  _buildDashboardSearchResults()
                else
                  _buildFrontMenuSection(),

                const SizedBox(height: 10),
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
