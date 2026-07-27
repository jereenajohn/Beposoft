import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:beposoft/Sales%20Directors/sd_add_attendance.dart';
import 'package:beposoft/Sales%20Directors/sd_add_team_staffs.dart';
import 'package:beposoft/Sales%20Directors/sd_all_dsr_reportpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_EMI.dart';
import 'package:beposoft/pages/ACCOUNTS/add_category.dart';
import 'package:beposoft/pages/ACCOUNTS/add_purpose_of_payment.dart';
import 'package:beposoft/pages/ACCOUNTS/add_self_attendance.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_warehouse.dart';
import 'package:beposoft/pages/ACCOUNTS/assetmanagement.dart';
import 'package:beposoft/pages/ACCOUNTS/assetmanegment2.dart';
import 'package:beposoft/pages/ACCOUNTS/bulk_customer_upload.dart';
import 'package:beposoft/pages/ACCOUNTS/cso_order_list.dart';
import 'package:beposoft/pages/ACCOUNTS/cso_sales_report_summary.dart';
import 'package:beposoft/pages/ACCOUNTS/cso_todays_bills.dart';
import 'package:beposoft/pages/ACCOUNTS/cso_waiting_for_approval_orderlist.dart';
import 'package:beposoft/pages/ACCOUNTS/dailyproductcategorywisecyclingskating.dart';
import 'package:beposoft/pages/ACCOUNTS/graph.dart';
import 'package:beposoft/pages/ACCOUNTS/grv_list.dart';
import 'package:beposoft/pages/ACCOUNTS/mailboxpage..dart';
import 'package:beposoft/pages/ACCOUNTS/order_list.dart';
import 'package:beposoft/pages/ACCOUNTS/performa_invoice_list.dart';
import 'package:beposoft/pages/ACCOUNTS/status_wise_orders_list.dart';
import 'package:beposoft/pages/ACCOUNTS/todays_orders_list.dart';
import 'package:beposoft/pages/ACCOUNTS/uploadbulkorders.dart';
import 'package:beposoft/pages/ADMIN/cso_grv_sales_return_summary.dart';
import 'package:beposoft/pages/ADMIN/localpurchaseorderscreen.dart';
import 'package:beposoft/pages/BDO/EmployeeLeaveFormPage%20.dart';
import 'package:beposoft/pages/HR/staff_attendance.dart';
import 'package:beposoft/pages/ACCOUNTS/view_staff.dart';
import 'package:beposoft/pages/ADMIN/grv_sales_return_summary.dart';
import 'package:beposoft/pages/ADMIN/sales_report_excel.dart';
import 'package:beposoft/pages/ADMIN/salesteam_cd_reportpage.dart';
import 'package:beposoft/pages/ADMIN/warehouse_summary.dart';
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

class cso_dashboard extends StatefulWidget {
  @override
  State<cso_dashboard> createState() => _cso_dashboardState();
}

class _cso_dashboardState extends State<cso_dashboard>
    with WidgetsBindingObserver {
  int todayBillsExcludingBepocartCount = 0;
  double totalTodayBillsExcludingBepocart = 0.0;
  int todayOrdersTotalAmountt = 0;
  bool isFetchingInboxMailCount = false;
  List<String> statusOptions = ["pending", "approved", "rejected"];
  List<Map<String, dynamic>> grvlist = [];
  List<Map<String, dynamic>> proforma = [];
  List<Map<String, dynamic>> salesReportList = [];
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  List<Map<String, dynamic>> shippedOrders = [];
  List<Map<String, dynamic>> Finance = [];
  int invoiceCreatedCount = 0;

  List<Map<String, dynamic>> csoFamilySummaryCards = [];

  String familyName = '';
  var family = '';
  bool isManager = false;
  List<Map<String, dynamic>> fam = [];

  String? username = '';

  Map<String, Map<String, dynamic>> familyWiseSummary = {};
  Map<String, Map<String, dynamic>> todayFamilyWiseSummary = {};

  int approval = 0;
  int confirm = 0;
  int approvalcount = 0;
  int confirmcount = 0;

  List<Map<String, dynamic>> expensedata = [];
  double totalAmount = 0;

  int todayShippedCount = 0;
  int todayOrdersTotalAmount = 0;

  double totalAdjustedOpeningBalance = 0.0;
  double totalClosingBalance = 0.0;
  double totalTodayPayments = 0.0;
  double totalTodayBanksAmount = 0.0;
  String profileImage = '';

  int grv = 0;
  int grvcount = 0;

  List<Map<String, dynamic>> parcel = [];
  Map<String, Map<String, double>> parcelData = {};
  String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  DateTime? selectedDate;
  int inboxMailCount = 0;
  Timer? mailCountTimer;
  drower d = drower();

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  Map<String, dynamic> productsData = {};

  Map<String, dynamic> salesReturnGrandTotal = {};
  bool salesReturnLoading = false;

  int teamWiseTotalTeams = 0;
  int teamWiseTotalMembers = 0;
  int teamWiseTotalPresent = 0;
  int teamWiseTotalAbsent = 0;
  int teamWiseTotalHalfDay = 0;
  int teamWiseGrandTotal = 0;
  List<Map<String, dynamic>> departmentAttendanceCards = [];

  int dashboardTotalStock = 0;
  double dashboardTotalRetailAmount = 0.0;
  double dashboardTotalLandingCostAmount = 0.0;
  double dashboardTotalSellingAmount = 0.0;
  bool dashboardInventoryLoading = false;

  List<Map<String, dynamic>> salesTeamCdTeamTotals = [];
  bool salesTeamCdLoading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _getUsername();
    getGrvList();
    fetchproformaData();
    getSalesReport();
    fetchOrderData();
    fetchshippedorders();
    getexpenselist();
    getFinancialReport();
    fetchorders();
    getprofiledata();
    fetchCsoFamilySummary();
    fetchOrdersSummaryFamilyData();
    fetchTeamWiseAttendanceCount();
    fetchGrvSummary();
    fetchDashboardInventorySummary();
    fetchSalesTeamCdTotalsForCso();
    fetchInvoiceCreatedCount();
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

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'Guest';
    });
  }

  Future<void> fetchInvoiceCreatedCount() async {
    try {
      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/orders/Invoice Created/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List ordersData = responseData['results'] ?? [];

        final filteredOrders = ordersData.where((orderData) {
          final status = (orderData['status'] ?? '').toString();
          final family = (orderData['family'] ?? '').toString().toLowerCase();

          return status == 'Invoice Created' && family != 'bepocart';
        }).toList();

        setState(() {
          invoiceCreatedCount = filteredOrders.length;
        });
      }
    } catch (error) {
      debugPrint('INVOICE CREATED COUNT ERROR: $error');
    }
  }

  Future<void> getprofiledata() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        setState(() {
          family = productsData['family'].toString();
          isManager = parsed['data']['is_manager'] ?? false;

          getGrvList();

          var matchingFamily = fam.firstWhere(
            (element) => element['id'].toString() == family,
            orElse: () => {'id': null, 'name': 'Unknown'},
          );

          familyName = matchingFamily['name'];
        });
      }
    } catch (error) {}
  }

  Future<void> fetchCsoFamilySummary() async {
    try {
      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/orders/summary/family/data/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List results = parsed['results'] ?? [];

        final filteredFamilies = results.where((item) {
          final familyName =
              (item['family_name'] ?? '').toString().toLowerCase();

          return familyName == 'cycling' || familyName == 'skating';
        }).map<Map<String, dynamic>>((item) {
          return {
            'family_id': item['family_id'],
            'family_name': item['family_name'],
            'today_count': item['today_count'] ?? 0,
            'today_total_amount': item['today_total_amount'] ?? 0.0,
            'month_count': item['month_count'] ?? 0,
            'month_total_amount': item['month_total_amount'] ?? 0.0,
            'payment_status_summary': item['payment_status_summary'] ?? {},
            'grv_return_summary': item['grv_return_summary'] ?? {},
          };
        }).toList();

        final int totalTodayBills = filteredFamilies.fold<int>(
          0,
          (sum, item) {
            return sum + ((item['today_count'] as num?)?.toInt() ?? 0);
          },
        );

        final double totalTodayVolume = filteredFamilies.fold<double>(
          0.0,
          (sum, item) {
            return sum +
                ((item['today_total_amount'] as num?)?.toDouble() ?? 0.0);
          },
        );

        setState(() {
          csoFamilySummaryCards = filteredFamilies;

          // Blue card values: Cycling + Skating only
          todayBillsExcludingBepocartCount = totalTodayBills;
          todayOrdersTotalAmountt = totalTodayVolume.round();
        });
      }
    } catch (e) {
      debugPrint('CSO FAMILY SUMMARY ERROR: $e');
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
        var productsData = parsed['results'];

        if (productsData != null && productsData is Iterable) {
          List<Map<String, dynamic>> orderList = [];
          Map<String, Map<String, dynamic>> familySummary = {};
          Map<String, Map<String, dynamic>> todayFamilySummary = {};

          int approval = 0;
          int confirm = 0;

          totalTodayBillsExcludingBepocart = 0.0;
          todayBillsExcludingBepocartCount = 0;

          String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

          for (var productData in productsData) {
            String family = productData['family'] ?? '';
            double amount =
                double.tryParse(productData['total_amount'].toString()) ?? 0.0;
            String orderDate = productData['order_date'] ?? '';

            var order = {
              'id': productData['id'],
              'invoice': productData['invoice'],
              'manage_staff': productData['manage_staff'],
              'customer': {
                'id': productData['customer']['id'],
                'name': productData['customer']['name'],
                'address': productData['billing_address']?['address'] ?? '',
              },
              'status': productData['status'],
              'order_date': orderDate,
              'updated_at': productData['updated_at'],
              'total_amount': amount,
              'family': family,
            };

            orderList.add(order);

            if (productData['status'] == 'Invoice Created') {
              approval++;
            } else if (productData['status'] == 'Invoice Approved') {
              confirm++;
            }

            familySummary.putIfAbsent(
              family,
              () => {
                'total_amount': 0.0,
                'order_count': 0,
              },
            );

            familySummary[family]!['total_amount'] += amount;
            familySummary[family]!['order_count'] += 1;

            if (orderDate == today) {
              todayFamilySummary.putIfAbsent(
                family,
                () => {
                  'total_amount': 0.0,
                  'order_count': 0,
                },
              );

              todayFamilySummary[family]!['total_amount'] += amount;
              todayFamilySummary[family]!['order_count'] += 1;

              if (family.toLowerCase() != 'bepocart') {
                totalTodayBillsExcludingBepocart += amount;
                todayBillsExcludingBepocartCount++;
              }
            }
          }

          var shippedOrdersToday = orderList.where((order) {
            return order['status'] == 'Shipped' &&
                order['updated_at'].toString().startsWith(today);
          }).toList();

          setState(() {
            orders = orderList;
            filteredOrders = orderList;
            shippedOrders = shippedOrdersToday;
            approvalcount = parsed['invoice_created_count'] ?? approval;
            confirmcount = parsed['invoice_approved_count'] ?? confirm;
            familyWiseSummary = familySummary;
            todayFamilyWiseSummary = todayFamilySummary;
            todayOrdersTotalAmountt = totalTodayBillsExcludingBepocart.toInt();
          });
        }
      }
    } catch (error) {}
  }

  Future<void> getexpenselist() async {
    try {
      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/expense/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        if (parsed['data'] != null && parsed['data'] is List) {
          final productsdata = parsed['data'];

          List<Map<String, dynamic>> expenselist = [];
          double total = 0.0;

          for (var productData in productsdata) {
            try {
              double amount = productData['amount'] != null
                  ? double.tryParse(productData['amount'].toString()) ?? 0.0
                  : 0.0;

              total += amount;

              expenselist.add({
                'id': productData['id']?.toString() ?? '',
                'purpose_of_payment':
                    productData['purpose_of_payment']?.toString() ?? '',
                'purpose_of_pay': productData['purpose_of_pay'],
                'amount': amount,
                'company': productData['company']['name']?.toString() ?? '',
                'added_by': productData['added_by']?.toString() ?? '',
                'transaction_id':
                    productData['transaction_id']?.toString() ?? '',
                'payed_by': productData['payed_by']['name']?.toString() ?? '',
                'expense_date': productData['expense_date']?.toString() ?? '',
                'catrgory': productData['categoryname']?.toString() ?? '',
                'name': productData['name']?.toString() ?? '',
                'quantity': productData['quantity']?.toString() ?? '',
              });
            } catch (e) {}
          }

          setState(() {
            expensedata = expenselist;
            totalAmount = total;
          });
        }
      }
    } catch (error) {}
  }

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
        double totalAmount = 0.0;

        for (var orderData in ordersData) {
          String rawOrderDate = orderData['order_date'] ?? "";

          try {
            DateTime parsedOrderDate =
                DateFormat('yyyy-MM-dd').parse(rawOrderDate);
            String formattedOrderDate =
                DateFormat('yyyy-MM-dd').format(parsedOrderDate);

            if (formattedOrderDate == today) {
              totalAmount += (orderData['total_amount'] ?? 0).toDouble();

              if (orderData['status'] == "Shipped") {
                shippedTodayCount++;
              }
            }
          } catch (e) {
            continue;
          }
        }

        setState(() {
          todayShippedCount = shippedTodayCount;
          todayOrdersTotalAmount = totalAmount.toInt();
        });
      } else {
        throw Exception("Failed to load order data");
      }
    } catch (error) {}
  }

  Future<void> getFinancialReport() async {
    final token = await getTokenFromPrefs();

    totalAdjustedOpeningBalance = 0.0;
    totalClosingBalance = 0.0;
    totalTodayPayments = 0.0;
    totalTodayBanksAmount = 0.0;

    try {
      final response = await http.get(
        Uri.parse('$api/api/finance-report/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final DateTime currentDate = DateTime.now();
        final DateTime today =
            DateTime(currentDate.year, currentDate.month, currentDate.day);

        List<Map<String, dynamic>> financeList = [];

        for (var bankData in parsed['bank_data'] ?? []) {
          String bankName = bankData['name'] ?? 'Unknown Bank';

          double openBalance =
              (bankData['open_balance'] as num?)?.toDouble() ?? 0.0;

          double totalPaymentsBeforeDate =
              (bankData['payments'] as List<dynamic>?)?.where((payment) {
                    final receivedAt =
                        DateTime.tryParse(payment['received_at'] ?? '');
                    if (receivedAt == null) return false;

                    final paymentDate = DateTime(
                      receivedAt.year,
                      receivedAt.month,
                      receivedAt.day,
                    );

                    return paymentDate.isBefore(today);
                  }).fold<double>(0.0, (sum, payment) {
                    return sum +
                        (double.tryParse(payment['amount'] ?? '') ?? 0.0);
                  }) ??
                  0.0;

          double totalBankExpensesBeforeDate =
              (bankData['banks'] as List<dynamic>?)?.where((bank) {
                    final expenseDate =
                        DateTime.tryParse(bank['expense_date'] ?? '');
                    if (expenseDate == null) return false;

                    final expenseDay = DateTime(
                      expenseDate.year,
                      expenseDate.month,
                      expenseDate.day,
                    );

                    return expenseDay.isBefore(today);
                  }).fold<double>(0.0, (sum, bank) {
                    return sum + (double.tryParse(bank['amount'] ?? '') ?? 0.0);
                  }) ??
                  0.0;

          double adjustedOpeningBalance = openBalance +
              totalPaymentsBeforeDate -
              totalBankExpensesBeforeDate;

          totalAdjustedOpeningBalance += adjustedOpeningBalance;

          double todayPayments =
              (bankData['payments'] as List<dynamic>?)?.where((payment) {
                    final receivedAt =
                        DateTime.tryParse(payment['received_at'] ?? '');
                    if (receivedAt == null) return false;

                    final paymentDate = DateTime(
                      receivedAt.year,
                      receivedAt.month,
                      receivedAt.day,
                    );

                    return paymentDate.isAtSameMomentAs(today);
                  }).fold<double>(0.0, (sum, payment) {
                    return sum +
                        (double.tryParse(payment['amount'] ?? '') ?? 0.0);
                  }) ??
                  0.0;

          totalTodayPayments += todayPayments;

          double todayBanksAmount =
              (bankData['banks'] as List<dynamic>?)?.where((bank) {
                    final expenseDate =
                        DateTime.tryParse(bank['expense_date'] ?? '');
                    if (expenseDate == null) return false;

                    final expenseDay = DateTime(
                      expenseDate.year,
                      expenseDate.month,
                      expenseDate.day,
                    );

                    return expenseDay.isAtSameMomentAs(today);
                  }).fold<double>(0.0, (sum, bank) {
                    return sum + (double.tryParse(bank['amount'] ?? '') ?? 0.0);
                  }) ??
                  0.0;

          totalTodayBanksAmount += todayBanksAmount;

          double closingBalance =
              adjustedOpeningBalance + todayPayments - todayBanksAmount;

          totalClosingBalance += closingBalance;

          financeList.add({
            'Bank Name': bankName,
            'Opening Balance': adjustedOpeningBalance.toStringAsFixed(2),
            'Closing Balance': closingBalance.toStringAsFixed(2),
            'Credit': todayPayments.toStringAsFixed(2),
            'Debit': todayBanksAmount.toStringAsFixed(2),
          });
        }

        setState(() {
          Finance = List<Map<String, dynamic>>.from(financeList);
        });
      } else {
        setState(() {
          Finance = [];
        });
      }
    } catch (e) {}
  }

  Future<void> getSalesReport() async {
    setState(() {});

    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/salesreport/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
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
                'amount': reportData['approved']['amount'],
              },
              'rejected': {
                'bills': reportData['rejected']['bills'],
                'amount': reportData['rejected']['amount'],
              },
            });
          }

          setState(() {
            salesReportList = salesReportDataList;
          });
        }
      }
    } catch (error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {});
    } finally {
      setState(() {});
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
      }
    } catch (error) {}
  }

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

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        List<Map<String, dynamic>> grvDataList = [];
        grv = 0;

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
      }
    } catch (error) {}
  }

  void _navigateToCsoOrderList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CsoOrderList(
          status: null,
        ),
      ),
    );
  }

  Future<void> fetchorders() async {
    final token = await getTokenFromPrefs();

    try {
      final response = await http.get(
        Uri.parse('$api/api/warehouse/get/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final orderdata = parsed['results'];
        List<Map<String, dynamic>> orderlist = [];

        parcelData.clear();

        for (var orderData in orderdata) {
          if (orderData['warehouses'] != null &&
              orderData['warehouses'] is List) {
            for (var warehouse in orderData['warehouses']) {
              String? parcelService = warehouse['parcel_service'];
              String? postofficeDate = warehouse['postoffice_date'];

              String selectedDateString = selectedDate != null
                  ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                  : todayDate;

              if (parcelService != null &&
                  parcelService.isNotEmpty &&
                  postofficeDate != null &&
                  postofficeDate == selectedDateString) {
                double actualWeight =
                    double.tryParse(warehouse['actual_weight'].toString()) ??
                        0.0;
                double parcelAmount =
                    double.tryParse(warehouse['parcel_amount'].toString()) ??
                        0.0;
                double weight =
                    double.tryParse(warehouse['weight'].toString()) ?? 0.0;

                if (!parcelData.containsKey(parcelService)) {
                  parcelData[parcelService] = {
                    'total_actual_weight': 0.0,
                    'total_parcel_amount': 0.0,
                    'weight': 0.0,
                  };
                }

                parcelData[parcelService]!['total_actual_weight'] =
                    (parcelData[parcelService]!['total_actual_weight'] ?? 0) +
                        actualWeight;

                parcelData[parcelService]!['total_parcel_amount'] =
                    (parcelData[parcelService]!['total_parcel_amount'] ?? 0) +
                        parcelAmount;

                parcelData[parcelService]!['total_weight'] =
                    (parcelData[parcelService]!['total_weight'] ?? 0) + weight;
              }
            }
          }
        }

        setState(() {
          parcel = orderlist;
        });
      }
    } catch (e) {}
  }

  void logout() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login()),
    );
  }

  Widget _buildDropdownTile(
    BuildContext context,
    String title,
    List<String> options,
  ) {
    return ExpansionTile(
      title: Text(title),
      children: options.map((option) {
        return ListTile(
          title: Text(option),
          onTap: () {
            Navigator.pop(context);
            d.navigateToSelectedPage(context, option);
          },
        );
      }).toList(),
    );
  }

  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  String _formatDashboardAmount(dynamic value) {
    final amount = _asDouble(value);
    final absAmount = amount.abs();
    final sign = amount < 0 ? '-' : '';

    if (absAmount >= 10000000) {
      return '$sign₹${(absAmount / 10000000).toStringAsFixed(2)} Cr';
    }
    if (absAmount >= 100000) {
      return '$sign₹${(absAmount / 100000).toStringAsFixed(2)} L';
    }
    if (absAmount >= 1000) {
      return '$sign₹${(absAmount / 1000).toStringAsFixed(2)}K';
    }
    return '$sign${_currency.format(absAmount)}';
  }

  String _teamShortName(String teamName) {
    final cleanName = teamName.trim();
    if (cleanName.isEmpty) return '-';

    final words = cleanName
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }

    return cleanName.length >= 2
        ? cleanName.substring(0, 2).toUpperCase()
        : cleanName.toUpperCase();
  }

  Future<void> fetchOrdersSummaryFamilyData() async {
    try {
      final token = await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        return;
      }

      final response = await http.get(
        Uri.parse(
          '$api/api/family/orders/summary/without/bepocart/',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          'CSO SALES SUMMARY FAILED: ${response.statusCode} ${response.body}',
        );
        return;
      }

      final decoded = jsonDecode(response.body);
      final overall = _asMap(decoded['overall']);

      if (!mounted) return;

      setState(() {
        productsData = overall;
      });
    } catch (e) {
      debugPrint('CSO SALES SUMMARY ERROR: $e');
    }
  }

  Future<void> fetchTeamWiseAttendanceCount() async {
    try {
      final token = await getTokenFromPrefs();
      if (token == null || token.isEmpty) return;

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final response = await http.get(
        Uri.parse('$api/api/staff/attendance/team/wise/count/').replace(
          queryParameters: {
            'start_date': today,
            'end_date': today,
          },
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) return;

      final parsed = jsonDecode(response.body);
      final summary = _asMap(parsed['summary']);
      final List data = parsed['data'] ?? [];

      int salesPresent = 0;
      int salesAbsent = 0;
      int salesHalfDay = 0;
      final cards = <Map<String, dynamic>>[];

      for (final item in data) {
        final teamName = (item['team_name'] ?? '').toString().trim();
        final upperName = teamName.toUpperCase();
        final present = _asInt(item['present_count']);
        final absent = _asInt(item['absent_count']);
        final halfDay = _asInt(item['half_day_count']);

        if (upperName.startsWith('SALES DEPARTMENT')) {
          salesPresent += present;
          salesAbsent += absent;
          salesHalfDay += halfDay;
        } else {
          cards.add({
            'title': teamName,
            'present': present,
            'absent': absent,
            'half_day': halfDay,
          });
        }
      }

      cards.insert(0, {
        'title': 'SALES DEPARTMENT',
        'present': salesPresent,
        'absent': salesAbsent,
        'half_day': salesHalfDay,
      });

      if (!mounted) return;
      setState(() {
        teamWiseTotalTeams = _asInt(summary['total_teams']);
        teamWiseTotalMembers = _asInt(summary['total_members']);
        teamWiseTotalPresent = _asInt(summary['total_present']);
        teamWiseTotalAbsent = _asInt(summary['total_absent']);
        teamWiseTotalHalfDay = _asInt(summary['total_half_day']);
        teamWiseGrandTotal = _asInt(summary['grand_total']);
        departmentAttendanceCards = cards;
      });
    } catch (e) {
      debugPrint('CSO ATTENDANCE SUMMARY ERROR: $e');
    }
  }

  Future<void> fetchGrvSummary() async {
    if (mounted) {
      setState(() {
        salesReturnLoading = true;
      });
    }

    try {
      final token = await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            salesReturnLoading = false;
          });
        }
        return;
      }

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final uri = Uri.parse(
        '$api/api/grv/family/payment/summary/without/bepocart/',
      ).replace(
        queryParameters: {
          'start_date': today,
          'end_date': today,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        setState(() {
          salesReturnGrandTotal = _asMap(
            decoded['grand_total'],
          );
          salesReturnLoading = false;
        });
      } else {
        debugPrint(
          'CSO SALES RETURN FAILED: '
          '${response.statusCode} ${response.body}',
        );

        setState(() {
          salesReturnGrandTotal = {};
          salesReturnLoading = false;
        });
      }
    } catch (e) {
      debugPrint('CSO SALES RETURN ERROR: $e');

      if (!mounted) return;

      setState(() {
        salesReturnGrandTotal = {};
        salesReturnLoading = false;
      });
    }
  }

  Future<String?> getWarehouseFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final intValue = prefs.getInt('warehouse');
    if (intValue != null) return intValue.toString();
    return prefs.getString('warehouse');
  }

  Future<void> fetchDashboardInventorySummary() async {
    final token = await getTokenFromPrefs();
    final warehouseId = await getWarehouseFromPrefs();

    if (token == null ||
        token.isEmpty ||
        warehouseId == null ||
        warehouseId.isEmpty) {
      return;
    }

    if (mounted) setState(() => dashboardInventoryLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$api/api/warehouse/products/gets/$warehouseId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final results = _asMap(parsed['results']);
        final summary = _asMap(results['summary']);
        setState(() {
          dashboardTotalStock = _asInt(summary['total_stock']);
          dashboardTotalRetailAmount =
              _asDouble(summary['total_retail_amount']);
          dashboardTotalLandingCostAmount =
              _asDouble(summary['total_landing_cost_amount']);
          dashboardTotalSellingAmount =
              _asDouble(summary['total_selling_amount']);
          dashboardInventoryLoading = false;
        });
      } else {
        setState(() => dashboardInventoryLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => dashboardInventoryLoading = false);
      debugPrint('CSO INVENTORY SUMMARY ERROR: $e');
    }
  }

  Future<void> fetchSalesTeamCdTotalsForCso() async {
    if (mounted) setState(() => salesTeamCdLoading = true);

    try {
      final token = await getTokenFromPrefs();
      if (token == null || token.isEmpty) return;

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final response = await http.get(
        Uri.parse('$api/api/sales/team/cd/report/').replace(
          queryParameters: {
            'start_date': today,
            'end_date': today,
          },
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List data = decoded['data'] ?? [];
        final teamTotals = data.map<Map<String, dynamic>>((team) {
          final teamTotal = _asMap(team['team_total']);
          return {
            'team_name': team['team_name'] ?? '',
            'avg_cd': _asDouble(teamTotal['AVG_CD']),
          };
        }).toList();

        setState(() {
          salesTeamCdTeamTotals = teamTotals;
          salesTeamCdLoading = false;
        });
      } else {
        setState(() {
          salesTeamCdTeamTotals = [];
          salesTeamCdLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        salesTeamCdTeamTotals = [];
        salesTeamCdLoading = false;
      });
      debugPrint('CSO SALES CD SUMMARY ERROR: $e');
    }
  }

  Widget _buildDashboardLineItem({
    required String title,
    required String value,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      height: 32,
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.22),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            flex: 4,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.90),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (value.isNotEmpty) ...[
            const SizedBox(width: 5),
            Expanded(
              flex: 6,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    value,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceTeamContainer({
    required String teamName,
    required int present,
    required int absent,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              teamName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text('P: $present',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 18),
          Text('A: $absent',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildSalesTeamContainer({
    required String teamName,
    required String avgCd,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              teamName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Text('Avg CD: $avgCd',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required VoidCallback onTap,
    List<String> lines = const [],
    Widget? bottom,
    String valueLabel = '',
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
                color: const Color(0xFF2C74FF).withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (value.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 22,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          valueLabel.isNotEmpty
                              ? '$valueLabel - $value'
                              : value,
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Expanded(
                  child: lines.isEmpty && bottom == null
                      ? const SizedBox.shrink()
                      : SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...lines.map((line) {
                                final parts = line.split(':');

                                final String titleText = parts.length > 1
                                    ? parts.first.trim()
                                    : line.trim();

                                final String valueText = parts.length > 1
                                    ? parts.sublist(1).join(':').trim()
                                    : '';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: _buildDashboardLineItem(
                                    title: titleText,
                                    value: valueText,
                                  ),
                                );
                              }),
                              if (bottom != null) ...[
                                if (lines.isNotEmpty) const SizedBox(height: 2),
                                bottom,
                              ],
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCsoDashboardCards() {
    final paymentSummary = _asMap(productsData['payment_status_summary']);
    final todayPayment = _asMap(paymentSummary['today']);
    final monthPayment = _asMap(paymentSummary['month']);
    final todayPaid = _asMap(todayPayment['paid']);
    final todayCod = _asMap(todayPayment['COD']);
    final monthPaid = _asMap(monthPayment['paid']);
    final monthCod = _asMap(monthPayment['COD']);

    final salesReturnPaid = _asMap(salesReturnGrandTotal['paid']);
    final salesReturnCod = _asMap(salesReturnGrandTotal['COD']);
    final todayCodReturnCount = _asInt(salesReturnCod['grv_count']);
    final todayCodReturnAmount = _asDouble(salesReturnCod['order_amount']);
    final todayCashReturnCount = _asInt(salesReturnPaid['grv_count']);
    final todayCashReturnAmount = _asDouble(salesReturnPaid['order_amount']);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,
        children: [
          _buildDashboardCard(
            title: 'Sales',
            value:
                'M.Total- ${_formatDashboardAmount(productsData['month_total_amount'])}',
            lines: [
              'MT. Invoices: ${_asInt(productsData['month_count'])}',
              'T. Paid: ${_asInt(todayPaid['count'])} | ${_formatDashboardAmount(todayPaid['total'])}',
              'T. COD: ${_asInt(todayCod['count'])} | ${_formatDashboardAmount(todayCod['total'])}',
              'M. Paid: ${_asInt(monthPaid['count'])} | ${_formatDashboardAmount(monthPaid['total'])}',
              'M. COD: ${_asInt(monthCod['count'])} | ${_formatDashboardAmount(monthCod['total'])}',
            ],
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => SalesReportExcelsummary())),
          ),
          _buildDashboardCard(
            title: 'Employees',
            value: 'Total $teamWiseTotalMembers',
            bottom: Column(
              children: [
                _buildDashboardLineItem(
                    title: 'Present',
                    value: '$teamWiseTotalPresent',
                    icon: Icons.person_pin_circle_rounded),
                const SizedBox(height: 6),
                _buildDashboardLineItem(
                    title: 'Absent',
                    value: '$teamWiseTotalAbsent',
                    icon: Icons.cancel_rounded),
                const SizedBox(height: 6),
                _buildDashboardLineItem(
                    title: 'Half Day',
                    value: '$teamWiseTotalHalfDay',
                    icon: Icons.access_time_filled_rounded),
              ],
            ),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => staff_list())),
          ),
          _buildDashboardCard(
            title: 'Attendance',
            value: '',
            bottom: departmentAttendanceCards.isEmpty
                ? const Text('Loading attendance...',
                    style: TextStyle(color: Colors.white))
                : Column(
                    children: departmentAttendanceCards.map((item) {
                      return _buildAttendanceTeamContainer(
                        teamName: _teamShortName(item['title'].toString()),
                        present: _asInt(item['present']),
                        absent: _asInt(item['absent']),
                      );
                    }).toList(),
                  ),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const HrTeamAttendanceScreen())),
          ),
          _buildDashboardCard(
            title: 'Sales Return',
            value: salesReturnLoading ? 'Loading...' : '',
            bottom: Column(
              children: [
                _buildDashboardLineItem(
                    title: 'Today COD SR INV', value: '$todayCodReturnCount'),
                const SizedBox(height: 8),
                _buildDashboardLineItem(
                    title: 'Amount',
                    value: _formatDashboardAmount(todayCodReturnAmount)),
                const SizedBox(height: 8),
                _buildDashboardLineItem(
                    title: 'Today Cash SR INV', value: '$todayCashReturnCount'),
                const SizedBox(height: 8),
                _buildDashboardLineItem(
                    title: 'Amount',
                    value: _formatDashboardAmount(todayCashReturnAmount)),
              ],
            ),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CsoGrvFamilyPaymentSummaryPage())),
          ),
          _buildDashboardCard(
            title: 'Inventory',
            valueLabel: 'WH',
            value: dashboardInventoryLoading
                ? 'Loading...'
                : _formatDashboardAmount(dashboardTotalSellingAmount),
            lines: [
              dashboardInventoryLoading
                  ? 'Retail: Loading...'
                  : 'Retail: ${_formatDashboardAmount(dashboardTotalRetailAmount)}',
              dashboardInventoryLoading
                  ? 'Landing: Loading...'
                  : 'Landing: ${_formatDashboardAmount(dashboardTotalLandingCostAmount)}',
            ],
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => WarehouseSummaryScreen())),
          ),
          _buildDashboardCard(
            title: 'Sales Analysis (DSR)',
            value: '',
            bottom: salesTeamCdLoading
                ? const Text('Loading CD report...',
                    style: TextStyle(color: Colors.white))
                : salesTeamCdTeamTotals.isEmpty
                    ? _buildSalesTeamContainer(
                        teamName: 'No Team', avgCd: '0.00%')
                    : Column(
                        children: salesTeamCdTeamTotals.map((team) {
                          return _buildSalesTeamContainer(
                            teamName:
                                _teamShortName(team['team_name'].toString()),
                            avgCd:
                                '${_asDouble(team['avg_cd']).toStringAsFixed(2)}%',
                          );
                        }).toList(),
                      ),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => SalesTeamCdReportPage())),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilySummarySection() {
    if (csoFamilySummaryCards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        const Text(
          'Division-Wise Performance',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        // Text(
        //   'Cycling and Skating sales overview',
        //   style: TextStyle(
        //     fontSize: 12,
        //     fontWeight: FontWeight.w500,
        //     color: Colors.grey.shade600,
        //   ),
        // ),
        // const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: csoFamilySummaryCards.length,
          itemBuilder: (context, index) {
            final item = csoFamilySummaryCards[index];

            final familyName = item['family_name'].toString();
            final todayCount = item['today_count'] ?? 0;
            final todayAmount =
                (item['today_total_amount'] as num?)?.toDouble() ?? 0.0;
            final monthCount = item['month_count'] ?? 0;
            final monthAmount =
                (item['month_total_amount'] as num?)?.toDouble() ?? 0.0;

            final paymentSummary = item['payment_status_summary'] ?? {};
            final todayPaid = paymentSummary['today']?['paid']?['total'] ?? 0.0;
            final monthPaid = paymentSummary['month']?['paid']?['total'] ?? 0.0;

            final grvSummary = item['grv_return_summary'] ?? {};
            final monthCodReturn =
                grvSummary['month']?['cod_return']?['total'] ?? 0.0;

            return TweenAnimationBuilder<Offset>(
              duration: Duration(milliseconds: 300 + (index * 120)),
              tween: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ),
              curve: Curves.easeOut,
              builder: (context, offset, child) {
                return Transform.translate(
                  offset: Offset(0, offset.dy * 40),
                  child: child,
                );
              },
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _navigateToCsoOrderList,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 46,
                            width: 46,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              familyName.toLowerCase() == 'cycling'
                                  ? Icons.directions_bike
                                  : Icons.ice_skating,
                              color: Colors.blue,
                              size: 27,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              familyName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF111827),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFamilyMiniCard(
                              title: 'Today Bills',
                              value: todayCount.toString(),
                              icon: Icons.receipt_long,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildFamilyMiniCard(
                              title: 'Today Amount',
                              value: '₹${todayAmount.toStringAsFixed(2)}',
                              icon: Icons.currency_rupee,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFamilyMiniCard(
                              title: 'Month Bills',
                              value: monthCount.toString(),
                              icon: Icons.calendar_month,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildFamilyMiniCard(
                              title: 'Month Amount',
                              value: '₹${monthAmount.toStringAsFixed(2)}',
                              icon: Icons.trending_up,
                            ),
                          ),
                        ],
                      ),
                      // const SizedBox(height: 10),
                      // Row(
                      //   children: [
                      //     Expanded(
                      //       child: _buildFamilyMiniCard(
                      //         title: 'Today Paid',
                      //         value: '₹${(todayPaid as num).toDouble().toStringAsFixed(2)}',
                      //         icon: Icons.payments_outlined,
                      //       ),
                      //     ),
                      //     const SizedBox(width: 10),
                      //     Expanded(
                      //       child: _buildFamilyMiniCard(
                      //         title: 'Month Paid',
                      //         value: '₹${(monthPaid as num).toDouble().toStringAsFixed(2)}',
                      //         icon: Icons.account_balance_wallet_outlined,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      // const SizedBox(height: 10),
                      // _buildFamilyMiniCard(
                      //   title: 'Month COD Return',
                      //   value:
                      //       '₹${(monthCodReturn as num).toDouble().toStringAsFixed(2)}',
                      //   icon: Icons.assignment_return_outlined,
                      // ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFamilyMiniCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardWithIcon({
    required String label,
    required String value,
    Color color = Colors.white,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildInfoCard(String value, String label, int notificationCount) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Text(
              value,
              style: const TextStyle(
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
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
        )
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
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, size: 36, color: Colors.blue),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (count != null && count > 0)
              Positioned(
                top: -8,
                right: -8,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[600],
                  child: Text(
                    count.toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowWithTwoColumns(
    String label1,
    dynamic value1,
    String label2,
    dynamic value2,
  ) {
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                Text(
                  value1.toString(),
                  style: const TextStyle(
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                Text(
                  value2.toString(),
                  style: const TextStyle(
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
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
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
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
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "lib/assets/logo.png",
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ],
            ),
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

          _buildDropdownTile(context, 'Customers', [
            'Add Customer',
            'Customers',
          ]),
          _buildDropdownTile(context, 'Proforma Invoice', [
            'New Proforma Invoice',
            'Proforma Invoice List',
          ]),
          _buildDropdownTile(
            context,
            'Orders',
            ['New Orders', 'View Orders List'],
          ),
          _buildDropdownTile(context, 'GRV', [
            'Create New GRV',
            'GRVs List',
          ]),
          _buildDropdownTile(context, 'BDO DSR', [
            'Add Team',
            'Add Team Members',
            'View All Team Members',
          ]),
          // if (isManager)
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Add Attendance Team'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SDAllMembersPage(),
                ),
              );
            },
          ),
          // if (isManager)
          ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('Add & Approve Attendance'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const sdAllAttendanceAddPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('View Attendance'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HrTeamAttendanceScreen(),
                ),
              );
            },
          ),

          // if (isManager)
          ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('Approve BDO Call Duration'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SdAllDsrReportPage(),
                ),
              );
            },
          ),
          // ListTile(
          //   title: const Text('Family Wise Excel Report'),
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) =>
          //             CyclingskatingCategoryDailyProductwiseReport(),
          //       ),
          //     );
          //   },
          // ),

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

          _buildDropdownTile(context, 'Reports', [
            'Sales Report Summary',
            'Sales Report',
            'Credit Sales Report',
            'COD Sales Report',
            'Product Stock Report',
            'Family Wise Excel Report',
            'Product Sale Report',
            'Order Comparison Report',
          ]),
          _buildDropdownTile(
              context, 'Staff', ['Add Staff', 'View Staff List']),
          // const Divider(),

          
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
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Logout'),
            onTap: () {
              logout();
            },
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Color(0xFF111827)),
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
        drawer: _buildDrawer(context),
        body: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      Text(
                        '$username',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blueAccent, Colors.lightBlueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('EEEE, dd MMMM yyyy')
                                  .format(DateTime.now()),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.95),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _navigateToCsoOrderList,
                              child: _buildCardWithIcon(
                                label: 'Today\'s Bills',
                                value:
                                    todayBillsExcludingBepocartCount.toString(),
                                color: Colors.white,
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _navigateToCsoOrderList,
                              child: _buildCardWithIcon(
                                label: 'Total Volume',
                                value:
                                    '₹ ${todayOrdersTotalAmountt.toString()}',
                                color: Colors.white,
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => csoOrderList2(
                                      status: 'Invoice Created',
                                    ),
                                  ),
                                );
                              },
                              child: _buildCardWithIcon(
                                label: 'Waiting for approval',
                                value: invoiceCreatedCount.toString(),
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  buildCsoDashboardCards(),
                  const SizedBox(height: 16),
                  _buildFamilySummarySection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
