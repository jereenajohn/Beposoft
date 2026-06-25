import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:excel/excel.dart' as ex;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SdAllDsrReportPage extends StatefulWidget {
  const SdAllDsrReportPage({super.key});

  @override
  State<SdAllDsrReportPage> createState() => _SdAllDsrReportPageState();
}

class _SdAllDsrReportPageState extends State<SdAllDsrReportPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;

  bool isLoading = true;
  bool isInitialLoading = true;
  bool isLoadingMore = false;
  bool hasNextPage = true;
  bool isExporting = false;
  bool isStaffLoading = false;
  bool isStateLoading = false;
  bool isDistrictLoading = false;
  bool isUpdatingStatus = false;

  String? nextPageUrl;

  int totalCount = 0;
  int staffCount = 0;
  String totalCallDuration = '00:00:00';
  double callDurationAverage8hrs = 0.0;
  double totalCallDurationMinutes = 0.0;
  double callDurationAverage = 0.0;

  int summaryActiveCount = 0;
  int summaryProductiveCount = 0;
  int summaryCreatedCount = 0;
  int summaryApprovedCount = 0;
  int summaryConfirmedCount = 0;
  int summaryRejectedCount = 0;

  int filteredTotalCount = 0;
  int filteredStaffCount = 0;
  String filteredTotalCallDuration = '00:00:00';
  double filteredCallDurationAverage8hrs = 0.0;
  double filteredTotalCallDurationMinutes = 0.0;
  double filteredCallDurationAverage = 0.0;

  DateTimeRange? selectedDateRange;
  String selectedSummaryFilter = '';

  int? loggedInFamilyId;
  int? selectedStaffId;
  String selectedStaffName = '';
  int? selectedStateId;
  String selectedStateName = '';
  int? selectedDistrictId;
  String selectedDistrictName = '';

  List<Map<String, dynamic>> dsrList = [];
  List<Map<String, dynamic>> filteredDsrList = [];
  List<Map<String, dynamic>> staffList = [];
  List<Map<String, dynamic>> stateList = [];
  List<Map<String, dynamic>> districtList = [];
  List<Map<String, dynamic>> allDistrictList = [];

  static const int noTeamFilterId = -1;

  String _normalize(String v) =>
      v.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  bool _isNoTeam(Map<String, dynamic> item) {
    final teamId = item['team'];
    final teamName = (item['team_name'] ?? '').toString().trim();
    return teamId == null || teamId.toString().isEmpty || teamName.isEmpty;
  }

  bool isTeamLoading = false;

  int? selectedTeamId;
  String selectedTeamName = '';

  List<Map<String, dynamic>> teamList = [];

  final Set<int> _expandedProductCards = {};

  final List<String> allowedStatuses = [
    // 'dsr created',
    'dsr approved',
    // 'dsr confirmed',
    'dsr rejected',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initPage();
  }

  Future<void> _initPage() async {
    loggedInFamilyId = await getFamilyIdFromProfile();
    await fetchStaffByFamily();
    await fetchTeams();
    await getState();
    await getDistricts();
    await fetchDsrList(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<String?> gettokenFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
    if (!mounted) return;

    if (dep == 'BDO') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => bdo_dashbord()));
    } else if (dep == 'SD') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => SdDashboard()));
    } else if (dep == 'BDM') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => bdm_dashbord()));
    } else if (dep == 'warehouse') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => WarehouseDashboard()));
    } else if (dep == 'Warehouse Admin') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => WarehouseAdmin()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => dashboard()));
    }
  }

  Future<int?> getFamilyIdFromProfile() async {
    try {
      final token = await gettokenFromPrefs();
      if (token == null || token.isEmpty) return null;

      final response = await http.get(
        Uri.parse('$api/api/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final familyId =
            parsed['data']?['family_id'] ?? parsed['data']?['family'];
        if (familyId is int) return familyId;
        return int.tryParse(familyId.toString());
      }
      return null;
    } catch (e) {
      debugPrint('PROFILE FETCH ERROR: $e');
      return null;
    }
  }

  Future<void> fetchStaffByFamily() async {
    try {
      if (mounted) setState(() => isStaffLoading = true);
      final token = await gettokenFromPrefs();
      int? familyId = loggedInFamilyId ?? await getFamilyIdFromProfile();
      if (familyId == null) {
        if (mounted) {
          setState(() {
            staffList = [];
            isStaffLoading = false;
          });
        }
        return;
      }
      loggedInFamilyId = familyId;

      final response = await http.get(
        Uri.parse('$api/api/users/family/$familyId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final List<Map<String, dynamic>> tempStaff = [];
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final data = parsed['data'] ?? [];
        for (final item in data) {
          tempStaff.add({
            'id': item['id'],
            'name': item['name']?.toString() ?? '',
            'department_name': item['department_name']?.toString() ?? '',
            'family_name': item['family_name']?.toString() ?? '',
            'email': item['email']?.toString() ?? '',
            'phone': item['phone']?.toString() ?? '',
          });
        }
      }

      if (!mounted) return;
      setState(() {
        staffList = tempStaff;
        isStaffLoading = false;
      });
    } catch (e) {
      debugPrint('STAFF FETCH ERROR: $e');
      if (!mounted) return;
      setState(() {
        staffList = [];
        isStaffLoading = false;
      });
    }
  }

  Future<void> fetchTeams() async {
    try {
      if (mounted) setState(() => isTeamLoading = true);

      final token = await gettokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/sales/teams/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final List<Map<String, dynamic>> tempTeams = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final data = parsed['data'] ?? [];

        for (final item in data) {
          tempTeams.add({
            'id': item['id'],
            'name': item['name']?.toString() ?? '',
            'team_leader_name': item['team_leader_name']?.toString() ?? '',
            'division_name': item['division_name']?.toString() ?? '',
          });
        }
      }

      if (!mounted) return;
      setState(() {
        teamList = [
          {
            'id': noTeamFilterId,
            'name': 'No Team',
            'team_leader_name': '',
            'division_name': '',
          },
          ...tempTeams,
        ];
        isTeamLoading = false;
      });
    } catch (e) {
      debugPrint('TEAM FETCH ERROR: $e');
      if (!mounted) return;
      setState(() {
        teamList = [];
        isTeamLoading = false;
      });
    }
  }

  Future<void> getState() async {
    try {
      if (mounted) setState(() => isStateLoading = true);
      final token = await gettokenFromPrefs();
      final response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final List<Map<String, dynamic>> tempStates = [];
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final data = parsed['data'] ?? [];
        for (final item in data) {
          tempStates
              .add({'id': item['id'], 'name': item['name']?.toString() ?? ''});
        }
      }

      if (!mounted) return;
      setState(() {
        stateList = tempStates;
        isStateLoading = false;
      });
    } catch (e) {
      debugPrint('STATE FETCH ERROR: $e');
      if (!mounted) return;
      setState(() {
        stateList = [];
        isStateLoading = false;
      });
    }
  }

  Future<void> getDistricts() async {
    try {
      if (mounted) setState(() => isDistrictLoading = true);
      final token = await gettokenFromPrefs();
      final response = await http.get(
        Uri.parse('$api/api/districts/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final List<Map<String, dynamic>> tempDistricts = [];
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final rawData = parsed is Map && parsed['data'] is List
            ? parsed['data']
            : parsed is List
                ? parsed
                : [];
        for (final item in rawData) {
          tempDistricts.add({
            'id': item['id'],
            'name': item['name']?.toString() ??
                item['district_name']?.toString() ??
                '',
            'state_id': item['state'] ??
                item['state_id'] ??
                item['state_name_id'] ??
                item['stateId'],
          });
        }
      }

      if (!mounted) return;
      setState(() {
        allDistrictList = tempDistricts;
        districtList = _getFilteredDistrictsForSelectedState();
        isDistrictLoading = false;
      });
    } catch (e) {
      debugPrint('DISTRICT FETCH ERROR: $e');
      if (!mounted) return;
      setState(() {
        allDistrictList = [];
        districtList = [];
        isDistrictLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredDistrictsForSelectedState() {
    if (selectedStateId == null)
      return List<Map<String, dynamic>>.from(allDistrictList);
    return allDistrictList.where((item) {
      final value = item['state_id'];
      final id = value is int ? value : int.tryParse(value.toString());
      return id == selectedStateId;
    }).toList();
  }

  void _refreshDistrictOptionsAfterStateChange() {
    districtList = _getFilteredDistrictsForSelectedState();
    if (selectedDistrictId != null) {
      final exists = districtList.any((e) => e['id'] == selectedDistrictId);
      if (!exists) {
        selectedDistrictId = null;
        selectedDistrictName = '';
      }
    }
  }

  String _formatDateForApi(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String formatDateOnly(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';
  }

  String formatDateTime(String value) {
    if (value.trim().isEmpty) return '-';
    try {
      final dt = DateTime.parse(value).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }

  String _safeText(dynamic value) {
    if (value == null) return '-';
    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  String _capitalizeWords(String value) {
    return value.split(' ').map((e) {
      if (e.isEmpty) return e;
      return e[0].toUpperCase() + e.substring(1);
    }).join(' ');
  }

  int _durationToSeconds(String value) {
    try {
      final parts = value.split(':');
      if (parts.length != 3) return 0;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final s = int.tryParse(parts[2]) ?? 0;
      return h * 3600 + m * 60 + s;
    } catch (_) {
      return 0;
    }
  }

  String _secondsToDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatAmount(dynamic value) {
    if (value == null) return '0';
    if (value is num) return value.toStringAsFixed(0);
    final cleaned = value.toString().replaceAll(',', '').trim();
    final parsed = double.tryParse(cleaned) ?? 0;
    return parsed.toStringAsFixed(0);
  }

  Map<String, String> _summaryFilterParams() {
    switch (selectedSummaryFilter) {
      case 'active':
        return {'call_status': 'active'};
      case 'productive':
        return {'call_status': 'productive'};
      case 'created':
        return {'status': 'dsr created'};
      case 'approved':
        return {'status': 'dsr approved'};
      case 'confirmed':
        return {'status': 'dsr confirmed'};
      case 'rejected':
        return {'status': 'dsr rejected'};
      default:
        return {};
    }
  }

  Uri _buildUri({String? nextUrl}) {
    if (nextUrl != null && nextUrl.isNotEmpty) return Uri.parse(nextUrl);

    final Map<String, String> queryParams = {};
    if (_searchController.text.trim().isNotEmpty)
      queryParams['search'] = _searchController.text.trim();
    if (selectedDateRange != null) {
      queryParams['start_date'] = _formatDateForApi(selectedDateRange!.start);
      queryParams['end_date'] = _formatDateForApi(selectedDateRange!.end);
    }
    if (selectedStaffName.trim().isNotEmpty) {
      queryParams['created_by'] = selectedStaffName.trim();
    }

    if (selectedStateName.trim().isNotEmpty) {
      queryParams['state'] = selectedStateName.trim();
    }

    if (selectedDistrictName.trim().isNotEmpty) {
      queryParams['district'] = selectedDistrictName.trim();
    }

    // if (selectedTeamId != null) {
    //   queryParams['team'] = selectedTeamId.toString();
    // }

    queryParams.addAll(_summaryFilterParams());

    return Uri.parse('$api/api/sales/team/member/daily/report/all/')
        .replace(queryParameters: queryParams);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoading &&
        !isLoadingMore &&
        hasNextPage) {
      fetchDsrList();
    }
  }

  void _calculateFilteredSummary(List<Map<String, dynamic>> list) {
    int active = 0;
    int productive = 0;
    int created = 0;
    int approved = 0;
    int confirmed = 0;
    int rejected = 0;
    int totalSeconds = 0;

    final Set<String> staffSet = {};

    for (final item in list) {
      final callStatus =
          (item['call_status'] ?? '').toString().toLowerCase().trim();
      final status = (item['status'] ?? '').toString().toLowerCase().trim();

      if (callStatus == 'active') active++;
      if (callStatus == 'productive') productive++;

      if (status == 'dsr created') created++;
      if (status == 'dsr approved') approved++;
      if (status == 'dsr confirmed') confirmed++;
      if (status == 'dsr rejected') rejected++;

      totalSeconds += _durationToSeconds(
        (item['call_duration'] ?? '00:00:00').toString(),
      );

      final staffId = item['created_by']?.toString() ?? '';
      if (staffId.isNotEmpty) staffSet.add(staffId);
    }

    filteredTotalCount = list.length;
    filteredStaffCount = staffSet.length;
    filteredTotalCallDuration = _secondsToDuration(totalSeconds);
    filteredTotalCallDurationMinutes = totalSeconds / 60.0;

    filteredCallDurationAverage =
        list.isEmpty ? 0.0 : filteredTotalCallDurationMinutes / list.length;

    filteredCallDurationAverage8hrs = staffSet.isEmpty
        ? 0.0
        : (totalSeconds / (staffSet.length * 8 * 3600)) * 100;

    summaryActiveCount = active;
    summaryProductiveCount = productive;
    summaryCreatedCount = created;
    summaryApprovedCount = approved;
    summaryConfirmedCount = confirmed;
    summaryRejectedCount = rejected;
  }

  Future<void> fetchDsrList({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        setState(() {
          isLoading = true;
          isInitialLoading = true;
          isLoadingMore = false;
          hasNextPage = true;
          nextPageUrl = null;
          dsrList.clear();
          filteredDsrList.clear();
          _expandedProductCards.clear();
        });
      } else {
        if (!hasNextPage || nextPageUrl == null) return;
        setState(() => isLoadingMore = true);
      }

      final token = await gettokenFromPrefs();
      final uri = isRefresh ? _buildUri() : _buildUri(nextUrl: nextPageUrl);
      debugPrint('FETCH ALL DSR URL: $uri');

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final Map<String, dynamic> results =
            Map<String, dynamic>.from(parsed['results'] ?? {});
        final Map<String, dynamic> summary =
            Map<String, dynamic>.from(results['summary'] ?? {});
        final Map<String, dynamic> callStatusSummary =
            Map<String, dynamic>.from(summary['call_status'] ?? {});
        final Map<String, dynamic> statusSummary =
            Map<String, dynamic>.from(summary['status'] ?? {});
        final List data = results['data'] is List ? results['data'] : [];

        final List<Map<String, dynamic>> tempList = [];
        for (final item in data) {
          final invoiceDetails = item['invoice_details'];
          final List<Map<String, dynamic>> products = [];

          if (invoiceDetails != null && invoiceDetails['items'] is List) {
            for (final p in invoiceDetails['items']) {
              final img = p['image']?.toString() ?? '';
              products.add({
                'product_id': p['product_id'],
                'name': p['name']?.toString() ?? '',
                'image': img.isNotEmpty ? '$api$img' : '',
                'quantity': p['quantity'] ?? 0,
              });
            }
          }

          tempList.add({
            'id': item['id'],
            'team': item['team'],
            'team_name': item['team_name']?.toString() ?? '',
            'division': item['division'],
            'division_name': item['division_name']?.toString() ?? '',
            'state': item['state'],
            'state_name': item['state_name']?.toString() ?? '',
            'district': item['district'],
            'district_name': item['district_name']?.toString() ?? '',
            'created_by': item['created_by'],
            'created_by_name': item['created_by_name']?.toString() ?? '',
            'invoice_id': item['invoice'],
            'invoice_no': item['invoice_number']?.toString() ??
                invoiceDetails?['invoice']?.toString() ??
                '',
            'invoice_amount':
                invoiceDetails?['total_amount']?.toString() ?? '0',
            'invoice_payment_status':
                invoiceDetails?['payment_status']?.toString() ?? '',
            'invoice_status': invoiceDetails?['status']?.toString() ?? '',
            'order_date': invoiceDetails?['order_date']?.toString() ?? '',
            'customer_name': item['customer_name']?.toString() ?? '',
            'phone': item['phone']?.toString() ?? '',
            'call_status': item['call_status']?.toString() ?? '',
            'status': item['status']?.toString() ?? '',
            'call_duration': item['call_duration']?.toString() ?? '00:00:00',
            'call_duration_percentage_8hrs':
                item['call_duration_percentage_8hrs'] ?? 0,
            'note': item['note']?.toString() ?? '',
            'created_at': item['created_at']?.toString() ?? '',
            'total_quantity':
                invoiceDetails?['total_quantity']?.toString() ?? '0',
            'total_items_count':
                invoiceDetails?['total_items_count']?.toString() ?? '0',
            'product_details': products,
          });
        }

        if (!mounted) return;
        setState(() {
          totalCount =
              parsed['count'] ?? summary['total_reports'] ?? tempList.length;
          staffCount = summary['staff_count'] ?? results['staff_count'] ?? 0;
          totalCallDuration =
              summary['total_call_duration']?.toString() ?? '00:00:00';
          totalCallDurationMinutes =
              _durationToSeconds(totalCallDuration) / 60.0;
          callDurationAverage8hrs = double.tryParse(
                  '${summary['call_duration_average_8hrs'] ?? 0}') ??
              0.0;
          callDurationAverage =
              double.tryParse('${summary['call_duration_average'] ?? 0}') ??
                  0.0;

          summaryActiveCount =
              int.tryParse('${callStatusSummary['active'] ?? 0}') ?? 0;
          summaryProductiveCount =
              int.tryParse('${callStatusSummary['productive'] ?? 0}') ?? 0;
          summaryCreatedCount =
              int.tryParse('${statusSummary['dsr_created'] ?? 0}') ?? 0;
          summaryApprovedCount =
              int.tryParse('${statusSummary['dsr_approved'] ?? 0}') ?? 0;
          summaryConfirmedCount =
              int.tryParse('${statusSummary['dsr_confirmed'] ?? 0}') ?? 0;
          summaryRejectedCount =
              int.tryParse('${statusSummary['dsr_rejected'] ?? 0}') ?? 0;

          if (isRefresh) {
            dsrList = tempList;
          } else {
            dsrList.addAll(tempList);
          }

          nextPageUrl = parsed['next'];
          hasNextPage =
              nextPageUrl != null && nextPageUrl.toString().isNotEmpty;
          isLoading = false;
          isInitialLoading = false;
          isLoadingMore = false;
        });

        _applyFilters();
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          isInitialLoading = false;
          isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed: ${response.body}')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isInitialLoading = false;
        isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')));
    }
  }

  // void _applyFilters() {
  //   filteredDsrList = List<Map<String, dynamic>>.from(dsrList);
  //   filteredTotalCount = totalCount;
  //   filteredStaffCount = staffCount;
  //   filteredTotalCallDuration = totalCallDuration;
  //   filteredTotalCallDurationMinutes = totalCallDurationMinutes;
  //   filteredCallDurationAverage = callDurationAverage;
  //   filteredCallDurationAverage8hrs = callDurationAverage8hrs;
  //   if (mounted) setState(() {});
  // }

  void _applyFilters() {
    List<Map<String, dynamic>> temp = List<Map<String, dynamic>>.from(dsrList);

    if (selectedTeamId != null) {
      temp = temp.where((item) {
        if (selectedTeamId == noTeamFilterId) {
          return _isNoTeam(item);
        }

        final itemTeamId = item['team'] is int
            ? item['team']
            : int.tryParse((item['team'] ?? '').toString());

        if (itemTeamId != null && itemTeamId == selectedTeamId) {
          return true;
        }

        return _normalize((item['team_name'] ?? '').toString()) ==
            _normalize(selectedTeamName);
      }).toList();
    }

    filteredDsrList = temp;

    filteredTotalCount = totalCount;
    filteredStaffCount = staffCount;
    filteredTotalCallDuration = totalCallDuration;
    filteredTotalCallDurationMinutes = totalCallDurationMinutes;
    filteredCallDurationAverage = callDurationAverage;
    filteredCallDurationAverage8hrs = callDurationAverage8hrs;

    if (mounted) setState(() {});
  }

  Future<void> _pickDateRange({bool fetchAfterPick = false}) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: selectedDateRange,
      helpText: 'Select Date Range',
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() => selectedDateRange = picked);
      if (fetchAfterPick) {
        await fetchDsrList(isRefresh: true);
      }
    }
  }

  void _clearDateRange() {
    if (!mounted) return;
    setState(() => selectedDateRange = null);
  }

  Future<void> _clearAllFilters({bool fetchAfterClear = true}) async {
    _debounce?.cancel();

    if (!mounted) return;
    setState(() {
      _searchController.clear();
      selectedDateRange = null;
      selectedSummaryFilter = '';

      selectedStaffId = null;
      selectedStaffName = '';

      selectedStateId = null;
      selectedStateName = '';

      selectedDistrictId = null;
      selectedDistrictName = '';

      selectedTeamId = null;
      selectedTeamName = '';

      districtList = List<Map<String, dynamic>>.from(allDistrictList);
    });

    if (fetchAfterClear) {
      await fetchDsrList(isRefresh: true);
    }
  }

  Color getCallStatusColor(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'productive') return Colors.green;
    if (s == 'active') return Colors.orange;
    return Colors.grey;
  }

  Color getDsrStatusColor(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'dsr rejected') return Colors.red;
    if (s == 'dsr approved') return Colors.green;
    if (s == 'dsr confirmed') return Colors.deepPurple;
    if (s == 'dsr created') return Colors.blue;
    return Colors.grey;
  }

  Widget buildInfoRow(String title, String value,
      {IconData? icon, Color? valueColor, FontWeight? valueWeight}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700),
            ),
          ),
          const Text(':  ',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey)),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: TextStyle(
                  fontSize: 12.5,
                  color: valueColor ?? Colors.black87,
                  fontWeight: valueWeight ?? FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildChip(String label, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20)),
        child: Text(
          label.trim().isEmpty ? '-' : _capitalizeWords(label),
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xff40B0FB)),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xff1E293B))),
      ],
    );
  }

  Widget _buildProductImagePlaceholder() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
          color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
      child: Icon(Icons.image_outlined, size: 26, color: Colors.grey.shade400),
    );
  }

  Widget _buildProductTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> p) {
    final String imageUrl = (p['image'] ?? '').toString().trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildProductImagePlaceholder())
                : _buildProductImagePlaceholder(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _safeText(p['name']),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildProductTag(
                        'Qty: ${p['quantity'] ?? '-'}', Colors.blue)
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProductDetails(int itemId, List<Map<String, dynamic>> products) {
    if (products.isEmpty) return const SizedBox.shrink();
    final bool isExpanded = _expandedProductCards.contains(itemId);
    final bool hasMore = products.length > 1;
    final visibleProducts = isExpanded ? products : [products.first];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        buildSectionTitle('Product Details', Icons.inventory_2_outlined),
        const SizedBox(height: 10),
        ...visibleProducts.map((p) => _buildProductRow(p)).toList(),
        if (hasMore)
          GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedProductCards.remove(itemId);
                } else {
                  _expandedProductCards.add(itemId);
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xff2196F3).withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xff2196F3).withOpacity(0.18)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 16, color: const Color(0xff2196F3)),
                  const SizedBox(width: 5),
                  Text(
                    isExpanded
                        ? 'See Less'
                        : 'See More (${products.length - 1} more product${products.length - 1 > 1 ? 's' : ''})',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff2196F3)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    VoidCallback? refreshSheet,
  }) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        onChanged: (_) {
          if (mounted) setState(() {});
          refreshSheet?.call();
        },
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xff64748B)),
          prefixIcon: Icon(icon, color: const Color(0xff64748B), size: 18),
          suffixIcon: controller.text.trim().isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close,
                      color: Color(0xff64748B), size: 18),
                  onPressed: () {
                    controller.clear();
                    if (mounted) setState(() {});
                    refreshSheet?.call();
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xffF8FAFC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: Color(0xff40B0FB), width: 1.1),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionField({
    required String hintText,
    required IconData icon,
    required String value,
    required bool isLoading,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final bool hasValue = value.trim().isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
            color: const Color(0xffF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300)),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xff64748B), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isLoading ? 'Loading...' : (hasValue ? value : hintText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    color: hasValue ? Colors.black87 : const Color(0xff64748B),
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500),
              ),
            ),
            if (isLoading)
              const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else if (hasValue && onClear != null)
              InkWell(
                onTap: onClear,
                child: const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child:
                        Icon(Icons.close, size: 16, color: Color(0xff64748B))),
              )
            else
              const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xff64748B), size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _showSearchableSelectionBottomSheet({
    required String title,
    required List<Map<String, dynamic>> items,
    required String searchHint,
    required String emptyText,
    required bool searchStaffFields,
    required Function(Map<String, dynamic>) onSelected,
  }) async {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> filteredItems =
        List<Map<String, dynamic>>.from(items);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void applySearch(String query) {
              final q = query.trim().toLowerCase();

              filteredItems = q.isEmpty
                  ? List<Map<String, dynamic>>.from(items)
                  : items.where((item) {
                      final name =
                          (item['name'] ?? '').toString().toLowerCase();
                      final phone =
                          (item['phone'] ?? '').toString().toLowerCase();
                      final department = (item['department_name'] ?? '')
                          .toString()
                          .toLowerCase();
                      final email =
                          (item['email'] ?? '').toString().toLowerCase();

                      if (searchStaffFields) {
                        return name.contains(q) ||
                            phone.contains(q) ||
                            department.contains(q) ||
                            email.contains(q);
                      }

                      return name.contains(q);
                    }).toList();

              setDialogState(() {});
            }

            return Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.70,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xffF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: searchController,
                          onChanged: applySearch,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: searchHint,
                            icon: const Icon(Icons.search, size: 20),
                            suffixIcon: searchController.text.trim().isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      searchController.clear();
                                      applySearch('');
                                    },
                                    icon: const Icon(Icons.close, size: 18),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: filteredItems.isEmpty
                            ? Center(child: Text(emptyText))
                            : ListView.separated(
                                itemCount: filteredItems.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];

                                  return ListTile(
                                    title: Text(
                                      item['name']?.toString() ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: searchStaffFields &&
                                            (item['department_name'] ?? '')
                                                .toString()
                                                .trim()
                                                .isNotEmpty
                                        ? Text(
                                            item['department_name'].toString(),
                                            style:
                                                const TextStyle(fontSize: 12),
                                          )
                                        : null,
                                    onTap: () {
                                      Navigator.pop(dialogContext);
                                      onSelected(item);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();
  }

  bool get _hasActiveFilters {
    return _searchController.text.trim().isNotEmpty ||
        selectedStaffName.trim().isNotEmpty ||
        selectedStateName.trim().isNotEmpty ||
        selectedDistrictName.trim().isNotEmpty ||
        selectedDateRange != null ||
        selectedTeamName.trim().isNotEmpty ||
        selectedSummaryFilter.trim().isNotEmpty;
  }

  Widget _buildSearchBar({
    VoidCallback? onApply,
    VoidCallback? onClear,
    VoidCallback? refreshSheet,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasActiveFilters)
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: onClear ?? () => _clearAllFilters(),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.red.withOpacity(0.15))),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restart_alt,
                          size: 15, color: Colors.redAccent),
                      SizedBox(width: 4),
                      Text('Clear',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.redAccent)),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          _buildFilterField(
            controller: _searchController,
            hintText: 'Search invoice / customer / district / staff',
            icon: Icons.search,
            refreshSheet: refreshSheet,
          ),
          const SizedBox(height: 10),
          _buildSelectionField(
            hintText: 'Select team',
            icon: Icons.groups_2_outlined,
            value: selectedTeamName,
            isLoading: isTeamLoading,
            onTap: () async {
              if (isTeamLoading) return;
              if (teamList.isEmpty) await fetchTeams();
              if (!mounted) return;

              if (teamList.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No teams found')),
                );
                return;
              }

              await _showSearchableSelectionBottomSheet(
                title: 'Select Team',
                items: teamList,
                searchHint: 'Search team',
                emptyText: 'No team found',
                searchStaffFields: false,
                onSelected: (item) {
                  setState(() {
                    selectedTeamId = item['id'] is int
                        ? item['id']
                        : int.tryParse(item['id'].toString());

                    selectedTeamName = item['name']?.toString() ?? '';
                  });
                  refreshSheet?.call();
                },
              );
            },
            onClear: () {
              setState(() {
                selectedTeamId = null;
                selectedTeamName = '';
              });
              refreshSheet?.call();
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSelectionField(
                  hintText: 'Select staff',
                  icon: Icons.person_outline,
                  value: selectedStaffName,
                  isLoading: isStaffLoading,
                  onTap: () async {
                    if (isStaffLoading) return;
                    if (staffList.isEmpty) await fetchStaffByFamily();
                    if (!mounted) return;

                    if (staffList.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No staff found')),
                      );
                      return;
                    }

                    await _showSearchableSelectionBottomSheet(
                      title: 'Select Staff',
                      items: staffList,
                      searchHint: 'Search staff',
                      emptyText: 'No staff found',
                      searchStaffFields: true,
                      onSelected: (item) {
                        setState(() {
                          selectedStaffId = item['id'] is int
                              ? item['id']
                              : int.tryParse(item['id'].toString());
                          selectedStaffName = item['name']?.toString() ?? '';
                        });
                        refreshSheet?.call();
                      },
                    );
                  },
                  onClear: () {
                    setState(() {
                      selectedStaffId = null;
                      selectedStaffName = '';
                    });
                    refreshSheet?.call();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSelectionField(
                  hintText: 'Select state',
                  icon: Icons.location_on_outlined,
                  value: selectedStateName,
                  isLoading: isStateLoading,
                  onTap: () async {
                    if (isStateLoading) return;
                    if (stateList.isEmpty) await getState();
                    if (!mounted) return;

                    if (stateList.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No states found')),
                      );
                      return;
                    }

                    await _showSearchableSelectionBottomSheet(
                      title: 'Select State',
                      items: stateList,
                      searchHint: 'Search state',
                      emptyText: 'No state found',
                      searchStaffFields: false,
                      onSelected: (item) {
                        setState(() {
                          selectedStateId = item['id'] is int
                              ? item['id']
                              : int.tryParse(item['id'].toString());
                          selectedStateName = item['name']?.toString() ?? '';
                          _refreshDistrictOptionsAfterStateChange();
                        });
                        refreshSheet?.call();
                      },
                    );
                  },
                  onClear: () {
                    setState(() {
                      selectedStateId = null;
                      selectedStateName = '';
                      selectedDistrictId = null;
                      selectedDistrictName = '';
                      districtList =
                          List<Map<String, dynamic>>.from(allDistrictList);
                    });
                    refreshSheet?.call();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSelectionField(
                  hintText: 'Select district',
                  icon: Icons.map_outlined,
                  value: selectedDistrictName,
                  isLoading: isDistrictLoading,
                  onTap: () async {
                    if (isDistrictLoading) return;
                    if (allDistrictList.isEmpty) await getDistricts();
                    if (!mounted) return;
                    final visibleDistricts =
                        _getFilteredDistrictsForSelectedState();
                    if (visibleDistricts.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No districts found')));
                      return;
                    }
                    await _showSearchableSelectionBottomSheet(
                      title: 'Select District',
                      items: visibleDistricts,
                      searchHint: 'Search district',
                      emptyText: 'No district found',
                      searchStaffFields: false,
                      onSelected: (item) {
                        setState(() {
                          selectedDistrictId = item['id'] is int
                              ? item['id']
                              : int.tryParse(item['id'].toString());
                          selectedDistrictName = item['name']?.toString() ?? '';
                        });
                        refreshSheet?.call();
                      },
                    );
                  },
                  onClear: () {
                    setState(() {
                      selectedDistrictId = null;
                      selectedDistrictName = '';
                    });
                    refreshSheet?.call();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    await _pickDateRange(fetchAfterPick: false);
                    refreshSheet?.call();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                        color: const Color(0xffF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300)),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range_outlined,
                            color: Color(0xff64748B), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedDateRange == null
                                ? 'Select date'
                                : '${formatDateOnly(selectedDateRange!.start)} to ${formatDateOnly(selectedDateRange!.end)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12.5,
                                color: selectedDateRange == null
                                    ? const Color(0xff64748B)
                                    : Colors.black87,
                                fontWeight: selectedDateRange == null
                                    ? FontWeight.w500
                                    : FontWeight.w600),
                          ),
                        ),
                        if (selectedDateRange != null)
                          InkWell(
                              onTap: () {
                                _clearDateRange();
                                refreshSheet?.call();
                              },
                              child: const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(Icons.close,
                                      size: 16, color: Color(0xff64748B))))
                        else
                          const Icon(Icons.keyboard_arrow_down,
                              color: Color(0xff64748B), size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onClear ?? () => _clearAllFilters(),
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('Clear Filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.30)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    onApply?.call();
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Apply Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2196F3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSummaryMiniCard(
      {required String title,
      required String value,
      required Color color,
      required IconData icon,
      required String filterKey}) {
    final bool isClickable = filterKey.isNotEmpty;
    final bool isSelected = selectedSummaryFilter == filterKey;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: !isClickable
          ? null
          : () {
              setState(
                  () => selectedSummaryFilter = isSelected ? '' : filterKey);
              fetchDsrList(isRefresh: true);
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isClickable
              ? (isSelected ? color.withOpacity(0.18) : color.withOpacity(0.08))
              : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isClickable
                  ? (isSelected ? color : color.withOpacity(0.12))
                  : color.withOpacity(0.12),
              width: isClickable && isSelected ? 1.4 : 1),
        ),
        child: Row(
          children: [
            Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: color)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700)),
                  const SizedBox(height: 3),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilterBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            void refreshSheet() {
              if (Navigator.of(sheetContext).canPop()) {
                sheetSetState(() {});
              }
            }

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(sheetContext).size.height * 0.82,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.filter_alt_outlined,
                            color: Color(0xff2196F3),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Filters',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
                        child: _buildSearchBar(
                          refreshSheet: refreshSheet,
                          onApply: () {
                            Navigator.pop(sheetContext);
                            Future.delayed(
                              const Duration(milliseconds: 250),
                              () {
                                if (mounted) fetchDsrList(isRefresh: true);
                              },
                            );
                          },
                          onClear: () async {
                            await _clearAllFilters(fetchAfterClear: false);
                            refreshSheet();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopSummary() {
    final int activeCount = summaryActiveCount;
    final int productiveCount = summaryProductiveCount;
    final int createdCount = summaryCreatedCount;
    final int approvedCount = summaryApprovedCount;
    final int confirmedCount = summaryConfirmedCount;
    final int rejectedCount = summaryRejectedCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8))
      ]),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  Color.fromARGB(255, 9, 137, 202),
                  Color.fromARGB(255, 46, 120, 239)
                ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.analytics_outlined,
                          color: Colors.white, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('All DSR Report Summary',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 3),
                        Text(
                          selectedSummaryFilter.isEmpty
                              ? 'All DSR report records'
                              : 'Filtered by ${selectedSummaryFilter[0].toUpperCase()}${selectedSummaryFilter.substring(1)}',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.85)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('Total $filteredTotalCount',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(
                        child: buildSummaryMiniCard(
                            title: 'Active Calls',
                            value: '$activeCount',
                            color: Colors.orange,
                            icon: Icons.phone_in_talk_outlined,
                            filterKey: 'active')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: buildSummaryMiniCard(
                            title: 'Productive Calls',
                            value: '$productiveCount',
                            color: Colors.green,
                            icon: Icons.trending_up_outlined,
                            filterKey: 'productive')),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: buildSummaryMiniCard(
                            title: 'DSR Created',
                            value: '$createdCount',
                            color: Colors.blue,
                            icon: Icons.edit_note_outlined,
                            filterKey: 'created')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: buildSummaryMiniCard(
                            title: 'DSR Approved',
                            value: '$approvedCount',
                            color: Colors.teal,
                            icon: Icons.verified_outlined,
                            filterKey: 'approved')),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: buildSummaryMiniCard(
                            title: 'DSR Confirmed',
                            value: '$confirmedCount',
                            color: Colors.deepPurple,
                            icon: Icons.task_alt_outlined,
                            filterKey: 'confirmed')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: buildSummaryMiniCard(
                            title: 'DSR Rejected',
                            value: '$rejectedCount',
                            color: Colors.red,
                            icon: Icons.cancel_outlined,
                            filterKey: 'rejected')),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: buildSummaryMiniCard(
                            title: 'Call Duration',
                            value: filteredTotalCallDuration,
                            color: const Color(0xff7C3AED),
                            icon: Icons.timer_outlined,
                            filterKey: '')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: buildSummaryMiniCard(
                            title: 'Staff Count',
                            value: '$filteredStaffCount',
                            color: const Color(0xff14B8A6),
                            icon: Icons.groups_outlined,
                            filterKey: '')),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: buildSummaryMiniCard(
                            title: 'Call Avg Mins',
                            value:
                                filteredCallDurationAverage.toStringAsFixed(2),
                            color: const Color(0xff0EA5E9),
                            icon: Icons.av_timer_outlined,
                            filterKey: '')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: buildSummaryMiniCard(
                            title: '8 Hrs %',
                            value:
                                '${filteredCallDurationAverage8hrs.toStringAsFixed(2)}%',
                            color: const Color(0xff8B5CF6),
                            icon: Icons.percent_outlined,
                            filterKey: '')),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStatusBottomSheet(Map<String, dynamic> item) async {
    String selectedStatus = (item['status'] ?? '').toString().trim();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setBottomState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(22))),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child: Container(
                            width: 42,
                            height: 5,
                            decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(20)))),
                    const SizedBox(height: 16),
                    const Text('Update DSR Status',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(
                        (item['invoice_no'] ?? '').toString().isEmpty
                            ? 'No Invoice'
                            : item['invoice_no'].toString(),
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 16),
                    ...allowedStatuses.map((status) => RadioListTile<String>(
                          value: status,
                          groupValue: selectedStatus,
                          contentPadding: EdgeInsets.zero,
                          title: Text(_capitalizeWords(status),
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          onChanged: isUpdatingStatus
                              ? null
                              : (value) {
                                  if (value != null)
                                    setBottomState(
                                        () => selectedStatus = value);
                                },
                        )),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isUpdatingStatus
                            ? null
                            : () async {
                                Navigator.pop(sheetContext);
                                final id = item['id'] is int
                                    ? item['id']
                                    : int.tryParse('${item['id']}') ?? 0;
                                await updateDsrStatus(id, selectedStatus);
                              },
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: isUpdatingStatus
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Update Status',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> updateDsrStatus(int id, String status) async {
    if (id == 0) return;
    try {
      setState(() => isUpdatingStatus = true);
      final token = await gettokenFromPrefs();
      final url =
          Uri.parse('$api/api/sales/team/member/daily/report/edit/$id/');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };
      final body = jsonEncode({'status': status});
      http.Response response =
          await http.put(url, headers: headers, body: body);
      if (response.statusCode == 405 || response.statusCode == 404) {
        response = await http.patch(url, headers: headers, body: body);
      }
      if (!mounted) return;
      if (response.statusCode == 200 ||
          response.statusCode == 202 ||
          response.statusCode == 204) {
        await fetchDsrList(isRefresh: true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Status updated successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed: ${response.body}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isUpdatingStatus = false);
    }
  }

  Widget _buildCard(Map<String, dynamic> item, int index) {
    final int itemId =
        item['id'] is int ? item['id'] : int.tryParse('${item['id']}') ?? index;
    final Color callColor = getCallStatusColor(item['call_status'] ?? '');
    final Color dsrColor = getDsrStatusColor(item['status'] ?? '');
    final List<Map<String, dynamic>> products =
        (item['product_details'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8))
      ]),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xff40B0FB), Color(0xff2196F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12)),
                    child: Center(
                        child: Text('${index + 1}',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            (item['invoice_no'] ?? '').toString().trim().isEmpty
                                ? 'No Invoice'
                                : item['invoice_no'].toString(),
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 3),
                        Text(_safeText(item['created_by_name']),
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.90),
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => _showStatusBottomSheet(item),
                      icon: const Icon(Icons.edit_outlined,
                          color: Colors.white, size: 22),
                      tooltip: 'Edit Status'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    buildChip(item['call_status'] ?? '', callColor),
                    buildChip(item['status'] ?? '', dsrColor,
                        onTap: () => _showStatusBottomSheet(item)),
                  ]),
                  const SizedBox(height: 18),
                  buildSectionTitle('Record Details', Icons.info_outline),
                  const SizedBox(height: 12),
                  buildInfoRow('Division', _safeText(item['division_name']),
                      icon: Icons.account_tree_outlined),
                  buildInfoRow('Team', _safeText(item['team_name']),
                      icon: Icons.groups_outlined),
                  buildInfoRow('Staff', _safeText(item['created_by_name']),
                      icon: Icons.badge_outlined),
                  buildInfoRow('Customer', _safeText(item['customer_name']),
                      icon: Icons.person_outline, valueWeight: FontWeight.w600),
                  buildInfoRow('Phone', _safeText(item['phone']),
                      icon: Icons.call_outlined),
                  buildInfoRow('Invoice No', _safeText(item['invoice_no']),
                      icon: Icons.receipt_long_outlined),
                  buildInfoRow('State', _safeText(item['state_name']),
                      icon: Icons.map_outlined),
                  buildInfoRow('District', _safeText(item['district_name']),
                      icon: Icons.location_city_outlined),
                  buildInfoRow('Duration', _safeText(item['call_duration']),
                      icon: Icons.timer_outlined,
                      valueColor: const Color(0xff7C3AED),
                      valueWeight: FontWeight.w700),
                  buildInfoRow('Duration % 8hrs',
                      '${(double.tryParse((item['call_duration_percentage_8hrs'] ?? 0).toString()) ?? 0).toStringAsFixed(2)}%',
                      icon: Icons.pie_chart_outline),
                  buildInfoRow('Invoice Amount',
                      '₹${_formatAmount(item['invoice_amount'])}',
                      icon: Icons.currency_rupee_outlined,
                      valueColor: Colors.green.shade700,
                      valueWeight: FontWeight.w700),
                  buildInfoRow(
                      'Payment', _safeText(item['invoice_payment_status']),
                      icon: Icons.account_balance_wallet_outlined),
                  buildInfoRow(
                      'Invoice Status', _safeText(item['invoice_status']),
                      icon: Icons.inventory_2_outlined),
                  buildInfoRow('Order Date', _safeText(item['order_date']),
                      icon: Icons.calendar_today_outlined),
                  buildInfoRow(
                      'Created At', formatDateTime(item['created_at'] ?? ''),
                      icon: Icons.access_time_outlined),
                  if ((item['note'] ?? '').toString().trim().isNotEmpty)
                    buildInfoRow('Note', _safeText(item['note']),
                        icon: Icons.sticky_note_2_outlined),
                  buildInfoRow('Total Qty', _safeText(item['total_quantity']),
                      icon: Icons.shopping_bag_outlined),
                  buildProductDetails(itemId, products),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => fetchDsrList(isRefresh: true),
      child: filteredDsrList.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildTopSummary(),
                const SizedBox(height: 120),
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 54, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No DSR records found',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: filteredDsrList.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) return _buildTopSummary();
                if (index == filteredDsrList.length + 1) {
                  return Column(
                    children: [
                      if (isLoadingMore)
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator()),
                      if (!hasNextPage && filteredDsrList.isNotEmpty)
                        const Padding(
                            padding: EdgeInsets.only(top: 4, bottom: 18),
                            child: Text('No more records',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12))),
                    ],
                  );
                }
                final item = filteredDsrList[index - 1];
                return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _buildCard(item, index - 1));
              },
            ),
    );
  }

  Future<void> exportToExcel() async {
    try {
      if (filteredDsrList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('No data available to export')));
        return;
      }
      setState(() => isExporting = true);
      final ex.Excel excel = ex.Excel.createExcel();
      const String sheetName = 'All DSR Report';
      final ex.Sheet sheet = excel[sheetName];
      excel.setDefaultSheet(sheetName);

      sheet.appendRow([
        'Sl No',
        'Date',
        'Staff',
        'Team',
        'Division',
        'Customer',
        'Phone',
        'State',
        'District',
        'Call Status',
        'DSR Status',
        'Call Duration',
        '8 Hrs %',
        'Invoice',
        'Invoice Amount',
        'Payment Status',
        'Invoice Status',
        'Order Date',
        'Note'
      ]);

      for (int i = 0; i < filteredDsrList.length; i++) {
        final item = filteredDsrList[i];
        sheet.appendRow([
          '${i + 1}',
          formatDateTime(item['created_at']?.toString() ?? ''),
          _safeText(item['created_by_name']),
          _safeText(item['team_name']),
          _safeText(item['division_name']),
          _safeText(item['customer_name']),
          _safeText(item['phone']),
          _safeText(item['state_name']),
          _safeText(item['district_name']),
          _safeText(item['call_status']),
          _safeText(item['status']),
          _safeText(item['call_duration']),
          _safeText(item['call_duration_percentage_8hrs']),
          _safeText(item['invoice_no']),
          _safeText(item['invoice_amount']),
          _safeText(item['invoice_payment_status']),
          _safeText(item['invoice_status']),
          _safeText(item['order_date']),
          _safeText(item['note']),
        ]);
      }

      final Directory directory = await getApplicationDocumentsDirectory();
      final String filePath =
          '${directory.path}/all_dsr_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final List<int>? fileBytes = excel.encode();
      if (fileBytes == null) throw Exception('Failed to generate Excel file');
      final File file = File(filePath);
      await file.writeAsBytes(fileBytes, flush: true);
      await Share.shareXFiles([XFile(file.path)], text: 'All DSR Report');
    } catch (e) {
      debugPrint('EXCEL EXPORT ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text('Excel export failed: $e')));
    } finally {
      if (mounted) setState(() => isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
              onPressed: _navigateBack,
              icon:
                  const Icon(Icons.arrow_back_ios_new, color: Colors.black87)),
          title: const Text('All DSR Report',
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              tooltip: 'Clear Filters',
              onPressed: _hasActiveFilters
                  ? () async {
                      await _clearAllFilters(fetchAfterClear: true);
                    }
                  : null,
              icon: Icon(
                Icons.close,
                color: _hasActiveFilters ? Colors.redAccent : Colors.grey,
              ),
            ),
            IconButton(
              tooltip: 'Filter',
              onPressed: _openFilterBottomSheet,
              icon: Icon(
                Icons.filter_alt_outlined,
                color: _hasActiveFilters
                    ? const Color(0xff2196F3)
                    : Colors.black87,
              ),
            ),
            IconButton(
              tooltip: 'Export',
              onPressed: isExporting ? null : exportToExcel,
              icon: isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_download_outlined,
                      color: Colors.black87),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }
}
