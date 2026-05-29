import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/grv_list.dart';
import 'package:beposoft/pages/ACCOUNTS/order_list.dart';
import 'package:beposoft/pages/ACCOUNTS/performa_invoice_list.dart';
import 'package:beposoft/pages/ACCOUNTS/view_staff.dart';
import 'package:beposoft/pages/BDM/approve_bdo__call_duration.dart';
import 'package:beposoft/pages/BDM/bdm_customer_list.dart';
import 'package:beposoft/pages/BDM/bdm_grv_list.dart';
import 'package:beposoft/pages/BDM/bdm_order_list.dart';
import 'package:beposoft/pages/BDM/bdm_staff_list.dart';
import 'package:beposoft/pages/BDM/bdm_today_order_list.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/logout_hekper.dart';
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
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';

class bdm_dashbord extends StatefulWidget {
  @override
  State<bdm_dashbord> createState() => _bdm_dashbordState();
}

class _bdm_dashbordState extends State<bdm_dashbord> {
  List<String> statusOptions = ["pending", "approved", "rejected"];
  List<Map<String, dynamic>> grvlist = [];
  List<Map<String, dynamic>> proforma = [];
  List<Map<String, dynamic>> salesReportList = [];
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  List<Map<String, dynamic>> shippedOrders = [];
  List<Map<String, dynamic>> fam = [];

  List<Map<String, dynamic>> myTeamDetailedSummary = [];
  bool isTeamSummaryLoading = false;
  String? selectedHourSlot;
  DateTime selectedTeamDate = DateTime.now();

  String? username = '';
  int familyTotalBills = 0;
  double familyTotalAmount = 0.0;
  int familyInvoiceCreatedBills = 0;
  int familyTodaysBills = 0;
  double familyTodaysTotalAmount = 0.0;
  bool isFamilySummaryLoading = false;

  @override
  void initState() {
    super.initState();
    _getUsername();
    fetchproformaData();
    initdata();
    getSalesReport();
    fetchOrderData();
    getcustomer();
    fetchMyTeamDetailedSummary();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAppUpdate(context);
    });
  }

  void initdata() async {
    await getfamily();
  }

  int approval = 0;
  int confirm = 0;
  int customers = 0;
  List<Map<String, dynamic>> customer = [];
  List<Map<String, dynamic>> filteredProducts = [];
  double totalAmountToday = 0.0;
  var family = '';
  String familyName = '';

  String formatApiDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String formatDisplayDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  Future<void> fetchFamilyWiseOrderSummary() async {
    try {
      if (family.toString().trim().isEmpty) {
        return;
      }

      setState(() {
        isFamilySummaryLoading = true;
      });

      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/orders/family/wise/summary/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        if (parsed['status'] == 'success' && parsed['data'] != null) {
          final List data = parsed['data'];

          Map<String, dynamic>? matchingFamily;

          for (final item in data) {
            if (item is Map<String, dynamic> &&
                item['family_id'].toString() == family.toString()) {
              matchingFamily = item;
              break;
            }
          }

          if (matchingFamily != null) {
            setState(() {
              familyTotalBills = int.tryParse(
                    matchingFamily?['total_bills'].toString() ?? "0",
                  ) ??
                  0;

              familyTotalAmount = double.tryParse(
                    matchingFamily?['total_amount'].toString() ?? "0",
                  ) ??
                  0.0;

              familyInvoiceCreatedBills = int.tryParse(
                    matchingFamily?['invoice_created_bills'].toString() ?? "0",
                  ) ??
                  0;

              familyTodaysBills = int.tryParse(
                    matchingFamily?['todays_bills'].toString() ?? "0",
                  ) ??
                  0;

              familyTodaysTotalAmount = double.tryParse(
                    matchingFamily?['todays_total_amount'].toString() ?? "0",
                  ) ??
                  0.0;
            });
          } else {
            setState(() {
              familyTotalBills = 0;
              familyTotalAmount = 0.0;
              familyInvoiceCreatedBills = 0;
              familyTodaysBills = 0;
              familyTodaysTotalAmount = 0.0;
            });
          }
        }
      } else {
        debugPrint(
          "Failed to fetch family wise order summary: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("Error in fetchFamilyWiseOrderSummary: $e");
    } finally {
      if (mounted) {
        setState(() {
          isFamilySummaryLoading = false;
        });
      }
    }
  }

  Future<void> pickTeamDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedTeamDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedTeamDate = picked;
        selectedHourSlot = null;
      });
      await fetchMyTeamDetailedSummary();
    }
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
        }
      }
    } catch (e) {}

    return true;
  }

  Future<void> fetchMyTeamDetailedSummary() async {
    setState(() {
      isTeamSummaryLoading = true;
    });

    try {
      final token = await getTokenFromPrefs();
      final String selectedDate = formatApiDate(selectedTeamDate);

      final Map<String, String> queryParams = {
        'start_date': selectedDate,
        'end_date': selectedDate,
      };

      if (selectedHourSlot != null && selectedHourSlot!.trim().isNotEmpty) {
        queryParams['time_duration'] = selectedHourSlot!.trim();
      }

      final uri = Uri.parse('$api/api/my/sales/team/detailed/summary/').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        if (parsed['success'] == true && parsed['data'] != null) {
          List<Map<String, dynamic>> tempList = [];

          for (var item in parsed['data']) {
            tempList.add({
              "team": {
                "team_id": item["team"]?["team_id"] ?? 0,
                "team_name": item["team"]?["team_name"] ?? "",
              },
              "summary": {
                "total_bill": item["summary"]?["total_bill"] ?? 0,
                "total_volume": item["summary"]?["total_volume"] ?? 0,
                "total_unbilled": item["summary"]?["total_unbilled"] ?? 0,
                "billing": item["summary"]?["billing"] ?? 0,
                "volume": item["summary"]?["volume"] ?? 0,
                "hourly_durations": item["summary"]?["hourly_durations"] ?? {},
                "new_customers": item["summary"]?["new_customers"] ?? 0,
                "new_conversions": item["summary"]?["new_conversions"] ?? 0,
                "total_call_count": item["summary"]?["total_call_count"] ?? 0,
                "total_call_duration":
                    item["summary"]?["total_call_duration"] ?? 0.0,
                "call_duration_average":
                    item["summary"]?["call_duration_average"] ?? 0.0,
                "call_duration_percentage_8hrs":
                    item["summary"]?["call_duration_percentage_8hrs"] ?? 0.0,
                "total_bdo_count": item["summary"]?["total_bdo_count"] ?? 0,
                "active_count": item["summary"]?["active_count"] ?? 0,
                "productive_count": item["summary"]?["productive_count"] ?? 0,
                "unique_customer_count":
                    item["summary"]?["unique_customer_count"] ?? 0,
                "report_count": item["summary"]?["report_count"] ?? 0,
                "present_count": item["summary"]?["present_count"] ?? 0,
                "absent_count": item["summary"]?["absent_count"] ?? 0,
                "half_day_count": item["summary"]?["half_day_count"] ?? 0,
                "total_team_count": item["summary"]?["total_team_count"] ?? 0,
              },
              "members": item["members"] != null
                  ? List<Map<String, dynamic>>.from(
                      item["members"].map((member) => {
                            "staff_id": member["staff_id"] ?? 0,
                            "staff_name": member["staff_name"] ?? "",
                            "attendance_summary": {
                              "present_count": member["attendance_summary"]
                                      ?["present_count"] ??
                                  0,
                              "absent_count": member["attendance_summary"]
                                      ?["absent_count"] ??
                                  0,
                              "half_day_count": member["attendance_summary"]
                                      ?["half_day_count"] ??
                                  0,
                            },
                            "attendance_details": member[
                                        "attendance_details"] !=
                                    null
                                ? List<Map<String, dynamic>>.from(
                                    member["attendance_details"]
                                        .map((attendance) => {
                                              "id": attendance["id"] ?? 0,
                                              "staff_id":
                                                  attendance["staff_id"] ?? 0,
                                              "staff_name":
                                                  attendance["staff_name"] ??
                                                      "",
                                              "status":
                                                  attendance["status"] ?? "",
                                              "created_at":
                                                  attendance["created_at"] ??
                                                      "",
                                              "updated_at":
                                                  attendance["updated_at"] ??
                                                      "",
                                            }),
                                  )
                                : [],
                            "summary": {
                              "total_bill":
                                  member["summary"]?["total_bill"] ?? 0,
                              "total_volume":
                                  member["summary"]?["total_volume"] ?? 0,
                              "total_unbilled":
                                  member["summary"]?["total_unbilled"] ?? 0,
                              "billing": member["summary"]?["billing"] ?? 0,
                              "volume": member["summary"]?["volume"] ?? 0,
                              "hourly_durations":
                                  member["summary"]?["hourly_durations"] ?? {},
                              "new_customers":
                                  member["summary"]?["new_customers"] ?? 0,
                              "new_conversions":
                                  member["summary"]?["new_conversions"] ?? 0,
                              "total_call_count":
                                  member["summary"]?["total_call_count"] ?? 0,
                              "total_call_duration": member["summary"]
                                      ?["total_call_duration"] ??
                                  0.0,
                              "call_duration_average": member["summary"]
                                      ?["call_duration_average"] ??
                                  0.0,
                              "call_duration_percentage_8hrs": member["summary"]
                                      ?["call_duration_percentage_8hrs"] ??
                                  0.0,
                              "total_bdo_count":
                                  member["summary"]?["total_bdo_count"] ?? 0,
                              "active_count":
                                  member["summary"]?["active_count"] ?? 0,
                              "productive_count":
                                  member["summary"]?["productive_count"] ?? 0,
                              "unique_customer_count": member["summary"]
                                      ?["unique_customer_count"] ??
                                  0,
                              "report_count":
                                  member["summary"]?["report_count"] ?? 0,
                              "present_count":
                                  member["summary"]?["present_count"] ?? 0,
                              "absent_count":
                                  member["summary"]?["absent_count"] ?? 0,
                              "half_day_count":
                                  member["summary"]?["half_day_count"] ?? 0,
                              "total_team_count":
                                  member["summary"]?["total_team_count"] ?? 0,
                            },
                            "reports": member["reports"] != null
                                ? List<Map<String, dynamic>>.from(
                                    member["reports"])
                                : [],
                          }),
                    )
                  : [],
            });
          }

          setState(() {
            myTeamDetailedSummary = tempList;
          });
        } else {
          setState(() {
            myTeamDetailedSummary = [];
          });
        }
      } else {
        debugPrint("Failed to fetch team summary: ${response.statusCode}");
        setState(() {
          myTeamDetailedSummary = [];
        });
      }
    } catch (e) {
      debugPrint("Error in fetchMyTeamDetailedSummary: $e");
      setState(() {
        myTeamDetailedSummary = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          isTeamSummaryLoading = false;
        });
      }
    }
  }

  String formatHourSlotLabel(String slot) {
    try {
      final parts = slot.split("-");
      if (parts.length != 2) return slot;

      String formatPart(String value, {required bool forcePm}) {
        final timeParts = value.split(":");
        int hour = int.tryParse(timeParts[0]) ?? 0;
        int minute = int.tryParse(timeParts[1]) ?? 0;

        int actualHour = hour;

        if (forcePm && hour < 12) {
          actualHour = hour + 12;
        }

        final suffix = actualHour >= 12 ? "PM" : "AM";

        int displayHour;
        if (actualHour == 0) {
          displayHour = 12;
        } else if (actualHour > 12) {
          displayHour = actualHour - 12;
        } else {
          displayHour = actualHour;
        }

        if (minute == 0) {
          return "$displayHour $suffix";
        }

        return "$displayHour:${minute.toString().padLeft(2, '0')} $suffix";
      }

      final startRaw = parts[0];
      final endRaw = parts[1];

      final startHour = int.tryParse(startRaw.split(":")[0]) ?? 0;
      final endHour = int.tryParse(endRaw.split(":")[0]) ?? 0;

      final startForcePm = startHour >= 1 && startHour <= 7;
      final endForcePm = endHour >= 1 && endHour <= 7;

      return "${formatPart(startRaw, forcePm: startForcePm)} - ${formatPart(endRaw, forcePm: endForcePm)}";
    } catch (e) {
      return slot;
    }
  }

  Future<void> refreshDashboardData() async {
    try {
      setState(() {
        selectedHourSlot = null;
      });

      await Future.wait([
        fetchproformaData(),
        getfamily(),
        getSalesReport(),
        fetchOrderData(),
        fetchMyTeamDetailedSummary(),
        fetchFamilyWiseOrderSummary(),
      ]);
    } catch (e) {
      debugPrint("Error refreshing dashboard: $e");
    }
  }

  String formatDoubleValue(dynamic value) {
    double number = 0.0;

    if (value is int) {
      number = value.toDouble();
    } else if (value is double) {
      number = value;
    } else {
      number = double.tryParse(value.toString()) ?? 0.0;
    }

    return number.toStringAsFixed(2);
  }

  String getAttendanceStatus(Map<String, dynamic> member) {
    final attendanceDetails =
        List<Map<String, dynamic>>.from(member["attendance_details"] ?? []);

    if (attendanceDetails.isNotEmpty) {
      final latestAttendance = attendanceDetails.first;
      final status = (latestAttendance["status"] ?? "").toString().trim();

      if (status.isNotEmpty) {
        return status.replaceAll("_", " ").toUpperCase();
      }
    }

    return "Attendance not added";
  }

  Color getAttendanceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "present":
        return Colors.green;
      case "half day":
        return Colors.orange;
      case "absent":
        return Colors.red;
      default:
        return Colors.grey;
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
      return "${(amount / 10000000).toStringAsFixed(2)} Cr";
    } else if (amount >= 100000) {
      return "${(amount / 100000).toStringAsFixed(2)} L";
    } else if (amount >= 1000) {
      return "${(amount / 1000).toStringAsFixed(2)} K";
    } else {
      return amount.toStringAsFixed(2);
    }
  }

  Widget _buildAttendanceSummaryChip(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "$title : $value",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAttendanceBodyCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSkeletonLine({
    double? width,
    double height = 14,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildTeamSummarySkeleton() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSkeletonLine(width: 180, height: 18),
                  const SizedBox(height: 10),
                  _buildSkeletonLine(width: 130, height: 12),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildSkeletonMetricCard()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSkeletonMetricCard()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildSkeletonMetricCard()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSkeletonMetricCard()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSkeletonLine(width: 120, height: 14),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 170,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildSkeletonMemberCard(),
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

  Widget _buildSkeletonMetricCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonLine(width: 70, height: 16),
          const SizedBox(height: 8),
          _buildSkeletonLine(width: 90, height: 12),
        ],
      ),
    );
  }

  Widget _buildSkeletonMemberCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonLine(width: 140, height: 16),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSkeletonMiniStat()),
              const SizedBox(width: 8),
              Expanded(child: _buildSkeletonMiniStat()),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildSkeletonMiniStat()),
              const SizedBox(width: 8),
              Expanded(child: _buildSkeletonMiniStat()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonMiniStat() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonLine(width: 60, height: 14),
          const SizedBox(height: 6),
          _buildSkeletonLine(width: 70, height: 11),
        ],
      ),
    );
  }

  Widget _buildAttendanceTableSkeleton() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSkeletonLine(width: 160, height: 16),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 110,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildSkeletonLine(height: 13)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSkeletonLine(height: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(
                    5,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _buildSkeletonLine(height: 13)),
                            const SizedBox(width: 12),
                            Container(
                              width: 90,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget buildAttendanceTableSection() {
    if (isTeamSummaryLoading) {
      return _buildTeamSummarySkeleton();
    }

    if (myTeamDetailedSummary.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Text(
            "No attendance data available",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final teamData = myTeamDetailedSummary.first;
    final team = teamData["team"] ?? {};
    final members = List<Map<String, dynamic>>.from(teamData["members"] ?? []);

    int presentCount = 0;
    int absentCount = 0;
    int halfDayCount = 0;

    for (final member in members) {
      final status = getAttendanceStatus(member).toLowerCase();

      if (status == "present") {
        presentCount++;
      } else if (status == "half day") {
        halfDayCount++;
      } else {
        absentCount++;
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${team["team_name"] ?? ""} - Attendance",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: pickTeamDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formatDisplayDate(selectedTeamDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // const SizedBox(height: 6),
                // Text(
                //   "Date: ${formatDisplayDate(selectedTeamDate)}",
                //   style: const TextStyle(
                //     color: Colors.white70,
                //     fontSize: 12,
                //     fontWeight: FontWeight.w500,
                //   ),
                // ),
                const SizedBox(height: 10),
                // Wrap(
                //   spacing: 10,
                //   runSpacing: 10,
                //   children: [
                //     _buildAttendanceSummaryChip(
                //       "Present",
                //       "$presentCount",
                //       Colors.green,
                //     ),
                //     _buildAttendanceSummaryChip(
                //       "Absent",
                //       "$absentCount",
                //       Colors.red,
                //     ),
                //     _buildAttendanceSummaryChip(
                //       "Half Day",
                //       "$halfDayCount",
                //       Colors.orange,
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Table(
              border: TableBorder.all(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              columnWidths: const {
                0: FlexColumnWidth(2.4),
                1: FlexColumnWidth(1.4),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                  ),
                  children: [
                    _buildAttendanceHeaderCell("Staff Name"),
                    _buildAttendanceHeaderCell("Status"),
                  ],
                ),
                ...members.map((member) {
                  final status = getAttendanceStatus(member);

                  return TableRow(
                    children: [
                      _buildAttendanceBodyCell(
                        member["staff_name"]?.toString() ?? "-",
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: getAttendanceStatusColor(status)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: getAttendanceStatusColor(status),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
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
          family = productsData['family'].toString() ?? '';

          getGrvList();

          var matchingFamily = fam.firstWhere(
            (element) => element['id'].toString() == family,
            orElse: () => {'id': null, 'name': 'Unknown'},
          );

          familyName = matchingFamily['name'];
        });
        fetchFamilyWiseOrderSummary();
        fetchbdmOrderData();
        getcustomer();
      }
    } catch (error) {}
  }

  Future<void> getfamily() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/familys/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];
        List<Map<String, dynamic>> familylist = [];

        for (var productData in productsData) {
          familylist.add({
            'id': productData['id'].toString(),
            'name': productData['name'],
          });
        }

        setState(() {
          fam = familylist;
        });
        await getprofiledata();
      }
    } catch (error) {}
  }

  Future<void> getcustomer() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/customers/'),
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
          if (familyName == productData['family']) {
            managerlist.add({
              'id': productData['id'],
              'name': productData['name'],
              'created_at': productData['created_at']
            });
          }
        }

        setState(() {
          customer = managerlist;
          filteredProducts = List.from(customer);
        });
      }
    } catch (error) {}
  }

  int totalOrdersToday = 0;
  int totalOrdersInvoiceCreated = 0;
  int Shippedorders = 0;
  int todaysbill = 0;
  int shippedbills = 0;
  int waitingbills = 0;

  Future<void> fetchbdmOrderData() async {
    try {
      totalOrdersToday = 0;
      totalOrdersInvoiceCreated = 0;
      Shippedorders = 0;
      totalAmountToday = 0.0;

      final token = await getTokenFromPrefs();

      String url = '$api/api/orders/';
      List<Map<String, dynamic>> orderList = [];

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

        List<Map<String, dynamic>> newOrders = [];

        DateTime currentDate = DateTime.now();
        String today = DateFormat('yyyy-MM-dd').format(currentDate);

        for (var orderData in ordersData) {
          String rawOrderDate = orderData['order_date'] ?? "";
          String formattedOrderDate = rawOrderDate;
          try {
            DateTime parsedOrderDate =
                DateFormat('yyyy-MM-dd').parse(rawOrderDate);
            formattedOrderDate =
                DateFormat('yyyy-MM-dd').format(parsedOrderDate);
          } catch (e) {}

          if (orderData['status'] != "Order Request by Warehouse") {
            if (familyName == orderData['family']) {
              newOrders.add({
                'id': orderData['id'],
                'family': orderData['family'],
                'invoice': orderData['invoice'],
                'manage_staff': orderData['manage_staff'],
                'customer': {
                  'id': orderData['customer']['id'],
                  'name': orderData['customer']['name'],
                  'phone': orderData['customer']['phone'],
                  'email': orderData['customer']['email'],
                  'address': orderData['customer']['address'],
                },
                'status': orderData['status'],
                'total_amount': orderData['total_amount'],
                'order_date': formattedOrderDate,
              });

              if (formattedOrderDate == today) {
                totalOrdersToday++;
                totalAmountToday +=
                    double.tryParse(orderData['total_amount'].toString()) ??
                        0.0;
              }

              if (orderData['status'] == "Invoice Created") {
                totalOrdersInvoiceCreated++;
              }

              if (formattedOrderDate == today &&
                  orderData['status'] == "Shipped") {
                Shippedorders++;
              }
            }
          }
        }

        setState(() {
          orders = newOrders;
          todaysbill = totalOrdersToday;
          waitingbills = totalOrdersInvoiceCreated;
          shippedbills = Shippedorders;
          filteredOrders = newOrders;
        });
      } else {
        throw Exception("Failed to load order data");
      }
    } catch (error) {}
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
            formattedOrderDate =
                DateFormat('yyyy-MM-dd').format(parsedOrderDate);
          } catch (e) {}

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
            'order_date': formattedOrderDate,
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
              order['order_date'] == formattedToday;
        }).toList();

        setState(() {
          orders = orderList;
          filteredOrders = orderList;
          shippedOrders = shippedOrdersToday;
        });
      }
    } catch (error) {}
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
      }
    } catch (error) {
    } finally {
      setState(() {});
    }
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  String getTodaysBills() {
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    var todaysReport = salesReportList.firstWhere(
      (report) => report['date'] == currentDate,
      orElse: () => {},
    );

    if (todaysReport['total_bills_in_date'] != null) {
      return todaysReport['total_bills_in_date'].toString();
    } else {
      return '0';
    }
  }

  Future<void> fetchproformaData() async {
    try {
      final token = await getTokenFromPrefs();
      final response = await http.get(
        Uri.parse('$api/api/performa/invoice/staff/'),
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
            'customer_name': productData['customermame'],
            'status': productData['status'],
            'total_amount': productData['total_amount'],
            'order_date': productData['order_date'],
            'created_at': '',
          });
        }

        if (mounted) {
          setState(() {
            proforma = performaInvoiceList;
          });
        }
      } else {}
    } catch (error) {}
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getusernameFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  int grv = 0;
  var grvpending;

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
        int grv = 0;

        for (var productData in productsData) {
          if (family.toString() == productData['family'].toString()) {
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
        }

        if (mounted) {
          setState(() {
            grvlist = grvDataList;
            grvpending = grv;
          });
        }
      }
    } catch (error) {}
  }

  Future<void> _getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final name = await getusernameFromPrefs();

    setState(() {
      username = name ?? 'Guest';
    });
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

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

    await Future.delayed(Duration(seconds: 2));

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
          d.navigateToSelectedPage3(context, option);
        },
      );
    }).toList(),
  );
}

  Widget buildMyTeamSummarySection() {
    if (isTeamSummaryLoading) {
      return _buildTeamSummarySkeleton();
    }

    if (myTeamDetailedSummary.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Text(
            "No team summary available",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final teamData = myTeamDetailedSummary.first;
    final team = Map<String, dynamic>.from(teamData["team"] ?? {});
    final summary = Map<String, dynamic>.from(teamData["summary"] ?? {});
    final members = List<Map<String, dynamic>>.from(teamData["members"] ?? []);

    Map<String, dynamic> teamHourlyDurations =
        Map<String, dynamic>.from(summary["hourly_durations"] ?? {});

    List<String> hourSlots = teamHourlyDurations.keys.toList();

    if (hourSlots.isEmpty && members.isNotEmpty) {
      final firstMemberSummary =
          Map<String, dynamic>.from(members.first["summary"] ?? {});
      teamHourlyDurations = Map<String, dynamic>.from(
        firstMemberSummary["hourly_durations"] ?? {},
      );
      hourSlots = teamHourlyDurations.keys.toList();
    }

    if (hourSlots.isEmpty) {
      hourSlots = [
        "09:00-10:00",
        "10:00-11:00",
        "11:00-12:00",
        "12:00-01:00",
        "01:00-02:00",
        "02:00-03:00",
        "03:00-04:00",
        "04:00-05:00",
        "05:00-06:00",
        "06:00-07:00",
      ];
    }

    final bool isHourlyFilterApplied =
        selectedHourSlot != null && selectedHourSlot!.isNotEmpty;

    final double teamDisplayDuration =
        (summary["total_call_duration"] ?? 0).toDouble();

    final String teamDurationTitle =
        isHourlyFilterApplied ? "Selected Hour CD" : "Total Team CD";

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        team["team_name"]?.toString() ?? "",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: pickTeamDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formatDisplayDate(selectedTeamDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isHourlyFilterApplied
                      ? "Time Range: ${formatHourSlotLabel(selectedHourSlot!)}"
                      : "Full Day Summary",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        "Total Bill",
                        "${summary["total_bill"] ?? 0}",
                        Icons.receipt_long,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        "Total Volume",
                        "${summary["total_volume"] ?? 0}",
                        Icons.inventory_2_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        teamDurationTitle,
                        "${formatDoubleValue(teamDisplayDuration)} mins",
                        Icons.call,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        "Average CD",
                        "${formatDoubleValue(summary["call_duration_average"] ?? 0)} mins",
                        Icons.av_timer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Team Members",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedHourSlot,
                          hint: const Text(
                            "Select Time Duration",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: "",
                              child: Text("Select Time Duration"),
                            ),
                            ...hourSlots.map((slot) {
                              return DropdownMenuItem<String>(
                                value: slot,
                                child: Text(formatHourSlotLabel(slot)),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) async {
                            setState(() {
                              if (value == null || value.isEmpty) {
                                selectedHourSlot = null;
                              } else {
                                selectedHourSlot = value;
                              }
                            });

                            await fetchMyTeamDetailedSummary();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  itemCount: members.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final memberSummary =
                        Map<String, dynamic>.from(member["summary"] ?? {});
                    final attendanceSummary = Map<String, dynamic>.from(
                      member["attendance_summary"] ?? {},
                    );

                    final double memberDisplayDuration =
                        (memberSummary["total_call_duration"] ?? 0).toDouble();

                    final String memberDurationTitle =
                        isHourlyFilterApplied ? "Selected Hour CD" : "Total CD";

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${index + 1}. ${member["staff_name"] ?? ""}",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMiniStat(
                                  memberDurationTitle,
                                  "${formatDoubleValue(memberDisplayDuration)} mins",
                                ),
                              ),
                              Expanded(
                                child: _buildMiniStat(
                                  "Calls",
                                  "${memberSummary["total_call_count"] ?? 0}",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMiniStat(
                                  "Bill",
                                  "${memberSummary["total_bill"] ?? 0}",
                                ),
                              ),
                              Expanded(
                                child: _buildMiniStat(
                                  "Volume",
                                  "${memberSummary["total_volume"] ?? 0}",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon(icon, color: Colors.blue, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
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
          actions: [],
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
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => bdm_dashbord()));
                },
              ),
              Divider(),
              _buildDropdownTile(context, 'Customers', [
                'Add Customer',
                'Customers',
              ]),
              _buildDropdownTile(context, 'Proforma Invoice', [
                'New Proforma Invoice',
                'Proforma Invoice List',
              ]),
              _buildDropdownTile(
                  context, 'Orders', ['New Orders', 'Orders List']),
              _buildDropdownTile(context, 'Approve BDO DSR', [
                'Add Team',
                'Add Team Members',
                'Add BDO Attendence',
                'View Call Duration List'
              ]),
              Divider(),
              ListTile(
                leading: Icon(Icons.person_2),
                title: Text('Staff'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => bdm_staff_list(
                        family: familyName,
                      ),
                    ),
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  await logoutUser(context);
                },
              ),
            ],
          ),
        ),),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: refreshDashboardData,
            color: Colors.blue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                        child: const CircleAvatar(
                          radius: 25,
                          backgroundImage: AssetImage('lib/assets/female.jpeg'),
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
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(
                                  //     builder: (context) => bdm_OrderList(
                                  //       status: null,
                                  //     ),
                                  //   ),
                                  // );
                                },
                                child: _buildInfoCard(
                                  isFamilySummaryLoading
                                      ? "..."
                                      : familyTotalBills.toString(),
                                  'Total Bills',
                                  0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildInfoCard(
                                isFamilySummaryLoading
                                    ? "..."
                                    : formatCompactAmount(familyTotalAmount),
                                'Total Volume',
                                0,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => bdm_OrderList(
                                        status: "Invoice Created",
                                      ),
                                    ),
                                  );
                                },
                                child: _buildInfoCard(
                                  isFamilySummaryLoading
                                      ? "..."
                                      : familyInvoiceCreatedBills.toString(),
                                  'Waiting For Approval',
                                  0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(
                                  //     builder: (context) => bdm_today_OrderList(
                                  //       status: null,
                                  //     ),
                                  //   ),
                                  // );
                                },
                                child: _buildInfoCard(
                                  isFamilySummaryLoading
                                      ? "..."
                                      : familyTodaysBills.toString(),
                                  'Today Bills',
                                  0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildInfoCard(
                                isFamilySummaryLoading
                                    ? "..."
                                    : formatCompactAmount(
                                        familyTodaysTotalAmount),
                                'Today Volume',
                                0,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: SizedBox(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => bdm_OrderList(
                                status: "Shipped",
                              ),
                            ),
                          );
                        },
                        child: _buildGridItem(
                          Icons.local_shipping,
                          'Shipped Orders',
                          shippedbills,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProformaInvoiceList(),
                            ),
                          );
                        },
                        child: _buildGridItem(
                          Icons.request_quote,
                          'Proforma Invoice',
                          proforma.length,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => approvebdocallduration(),
                            ),
                          );
                        },
                        child: _buildGridItem(
                          Icons.receipt_long,
                          'BDO CD List',
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => bdm_customer_list(),
                            ),
                          );
                        },
                        child: _buildGridItem(
                          Icons.pending_actions,
                          'Customers',
                          customer.length,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  buildMyTeamSummarySection(),
                  const SizedBox(height: 12),
                  buildAttendanceTableSection(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String value, String label, int notificationCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
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
              if (notificationCount > 0)
                Positioned(
                  top: -8,
                  right: -8,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      notificationCount.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
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
                  SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
