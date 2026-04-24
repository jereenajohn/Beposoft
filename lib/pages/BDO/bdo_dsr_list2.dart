import 'dart:convert';

import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BdoDsrList2 extends StatefulWidget {
  const BdoDsrList2({super.key});

  @override
  State<BdoDsrList2> createState() => _BdoDsrList2State();
}

class _BdoDsrList2State extends State<BdoDsrList2> {
  List<dynamic> reportsList = [];
  List<Map<String, dynamic>> stat = [];
  bool isLoading = true;
  bool isLoadingMore = false;

  int currentPage = 1;
  int totalCount = 0;
  int totalPages = 0;
  String? nextPageUrl;
  String? previousPageUrl;
  bool hasMore = true;

  List<int> allocatedStateIds = [];

  List<Map<String, dynamic>> districts = [];
  List<Map<String, dynamic>> filteredDistricts = [];

  int? selectedStateId;
  int? selectedDistrictId;

  final int itemsPerPage = 50;

  DateTime? startDate;
  DateTime? endDate;

  Map<int, Map<String, dynamic>> prefetchedReports = {};

  final ScrollController _scrollController = ScrollController();

  static const Color primaryBlue = Color(0xff1677FF);
  static const Color lightBlue = Color(0xffEAF3FF);
  static const Color darkText = Color(0xff1F2937);
  static const Color subText = Color(0xff6B7280);
  static const Color successGreen = Color(0xff16A34A);
  static const Color warningOrange = Color(0xffF59E0B);

  bool _isValidationDialogOpen = false;

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
    if (!mounted) return;

    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => bdo_dashbord()),
      );
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => bdm_dashbord()),
      );
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WarehouseDashboard()),
      );
    } else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WarehouseAdmin()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
  }

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  int _parseInt(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  void _setControllerValue(TextEditingController controller, String value) {
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _showValidationPopup(String message) async {
    if (!mounted || _isValidationDialogOpen) return;

    _isValidationDialogOpen = true;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text(
                "Invalid Value",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );

    _isValidationDialogOpen = false;
  }

  Future<Map<String, dynamic>> getSalesTeamDailyReports({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
  }) async {
    try {
      final token = await gettokenFromPrefs();

      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': itemsPerPage.toString(),
      };

      if (startDate != null) {
        queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
      }
      if (endDate != null) {
        queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
      }

      final url = Uri.parse("$api/api/sales/team/daily/report/add/").replace(
        queryParameters: queryParams,
      );

      print("Pagination URL: $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        final paginationData = jsonData['results'] ?? {};
        final List<dynamic> reportList = paginationData['data'] ?? [];

        final count = jsonData['count'] ?? 0;
        final next = jsonData['next'];
        final previous = jsonData['previous'];

        return {
          'data': reportList,
          'count': count,
          'next': next,
          'previous': previous,
        };
      } else {
        return {
          'data': [],
          'count': 0,
          'next': null,
          'previous': null,
        };
      }
    } catch (e) {
      print("❌ EXCEPTION: $e");
      return {
        'data': [],
        'count': 0,
        'next': null,
        'previous': null,
      };
    }
  }

  Future<Map<String, dynamic>?> getReportById(int reportId) async {
    try {
      final token = await gettokenFromPrefs();
      final url = Uri.parse("$api/api/sales/team/daily/report/edit/$reportId/");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['data'] != null) {
          return Map<String, dynamic>.from(jsonData['data']);
        }

        if (jsonData['results']?['data'] != null) {
          return Map<String, dynamic>.from(jsonData['results']['data']);
        }

        return Map<String, dynamic>.from(jsonData);
      }

      return null;
    } catch (e) {
      print("❌ EXCEPTION in getReportById: $e");
      return null;
    }
  }

  Future<bool> updateReport(
    int reportId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      final token = await gettokenFromPrefs();
      final url = Uri.parse("$api/api/sales/team/daily/report/edit/$reportId/");

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updatedData),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ EXCEPTION in updateReport: $e");
      return false;
    }
  }

  Future<void> _prefetchAllReports(List<dynamic> reports) async {
    for (final report in reports) {
      final id = report['id'] as int;
      if (prefetchedReports.containsKey(id)) continue;

      final detail = await getReportById(id);
      if (detail != null && mounted) {
        prefetchedReports[id] = detail;
      }
    }
  }

  Future<void> loadPage(int page) async {
    setState(() {
      isLoading = true;
      currentPage = page;
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    final result = await getSalesTeamDailyReports(
      startDate: startDate,
      endDate: endDate,
      page: page,
    );

    final newReports = result['data'] as List<dynamic>;
    totalCount = result['count'];
    nextPageUrl = result['next'];
    previousPageUrl = result['previous'];
    totalPages = totalCount > 0 ? (totalCount / itemsPerPage).ceil() : 1;
    hasMore = nextPageUrl != null;

    setState(() {
      reportsList = newReports;
      isLoading = false;
    });

    _prefetchAllReports(newReports);
  }

  Future<void> loadReports({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        currentPage = 1;
        reportsList.clear();
        isLoading = true;
        hasMore = true;
      });
    }

    await loadPage(currentPage);
  }

  Future<void> refreshReports() async {
    currentPage = 1;
    hasMore = true;
    prefetchedReports.clear();
    await loadReports(isRefresh: true);
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
        currentPage = 1;
        hasMore = true;
      });
      prefetchedReports.clear();
      await refreshReports();
    }
  }

  Future<void> _clearDateFilter() async {
    setState(() {
      startDate = null;
      endDate = null;
      currentPage = 1;
      hasMore = true;
    });
    prefetchedReports.clear();
    await refreshReports();
  }

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> getDistricts() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/districts/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> districtList = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var data = parsed['data'] ?? [];

        for (var item in data) {
          districtList.add({
            "id": item["id"],
            "name": item["name"],
            "state_name": item["state_name"],
            "state_id": item["state"],
          });
        }

        if (!mounted) return;
        setState(() {
          districts = districtList;
        });
      }
    } catch (e) {
      print("District fetch error: $e");
    }
  }

  void filterDistrictByState(int stateId) {
    List<Map<String, dynamic>> filtered =
        districts.where((d) => d["state_id"] == stateId).toList();

    setState(() {
      filteredDistricts = filtered;
      selectedDistrictId = null;
    });
  }

  Future<void> loadAllocatedStatesAndStates() async {
    try {
      final token = await gettokenFromPrefs();

      var profileResponse = await http.get(
        Uri.parse('$api/api/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (profileResponse.statusCode == 200) {
        final profileParsed = jsonDecode(profileResponse.body);
        List allocated = profileParsed["data"]["allocated_states"] ?? [];
        allocatedStateIds = List<int>.from(allocated);
      } else {
        return;
      }

      var stateResponse = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (stateResponse.statusCode == 200) {
        final stateParsed = jsonDecode(stateResponse.body);
        List data = stateParsed["data"] ?? [];

        List<Map<String, dynamic>> statelist = [];

        for (var item in data) {
          int stateId = item["id"];
          if (allocatedStateIds.contains(stateId)) {
            statelist.add({
              "id": stateId,
              "name": item["name"],
            });
          }
        }

        if (!mounted) return;
        setState(() {
          stat = statelist;
        });
      }
    } catch (e) {
      print("State fetch error: $e");
    }
  }

  void showEditDialog(Map<String, dynamic> report) async {
    final outerContext = context;
    final messenger = ScaffoldMessenger.of(context);
    final int reportId = report['id'] as int;

    Map<String, dynamic>? latestReport = prefetchedReports[reportId];

    if (latestReport == null) {
      showDialog(
        context: outerContext,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      latestReport = await getReportById(reportId);

      if (Navigator.of(outerContext, rootNavigator: true).canPop()) {
        Navigator.of(outerContext, rootNavigator: true).pop();
      }

      if (latestReport == null) {
        messenger.showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("Failed to load report data"),
          ),
        );
        return;
      }

      prefetchedReports[reportId] = latestReport;
    }

    if (stat.isEmpty) {
      await loadAllocatedStatesAndStates();
    }

    if (districts.isEmpty) {
      await getDistricts();
    }

    final unbilledController = TextEditingController(
      text: latestReport['unbilled']?.toString() ?? '0',
    );
    final billedController = TextEditingController(
      text: latestReport['billed']?.toString() ?? '0',
    );
    final newCustomersController = TextEditingController(
      text: latestReport['new_customers']?.toString() ?? '0',
    );
    final newConversionsController = TextEditingController(
      text: latestReport['new_conversions']?.toString() ?? '0',
    );

    bool isAdjustingBilled = false;
    bool isAdjustingConversion = false;

    void validateBilledAgainstUnbilled({bool showPopup = false}) {
      if (isAdjustingBilled) return;

      final int unbilled = _parseInt(unbilledController.text);
      final int billed = _parseInt(billedController.text);

      if (billed > unbilled) {
        isAdjustingBilled = true;
        _setControllerValue(billedController, unbilled.toString());
        isAdjustingBilled = false;

        if (showPopup) {
          _showValidationPopup(
            "Billed customer cannot be greater than unbilled customer",
          );
        }
      }
    }

    void validateConversionAgainstNewCustomers({bool showPopup = false}) {
      if (isAdjustingConversion) return;

      final int newCustomers = _parseInt(newCustomersController.text);
      final int newConversions = _parseInt(newConversionsController.text);

      if (newConversions > newCustomers) {
        isAdjustingConversion = true;
        _setControllerValue(
          newConversionsController,
          newCustomers.toString(),
        );
        isAdjustingConversion = false;

        if (showPopup) {
          _showValidationPopup(
            "New conversion cannot be greater than new customers",
          );
        }
      }
    }

    unbilledController.addListener(() {
      validateBilledAgainstUnbilled();
    });

    newCustomersController.addListener(() {
      validateConversionAgainstNewCustomers();
    });

    int currentStateId = latestReport['state'] ?? report['state'] ?? 0;
    int currentDistrictId = latestReport['district'] ?? report['district'] ?? 0;

    showDialog(
        context: outerContext,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, dialogSetState) {
              final List<Map<String, dynamic>> currentFilteredDistricts =
                  districts
                      .where((d) => d["state_id"] == currentStateId)
                      .toList();

              final bool isValidState =
                  stat.any((s) => s["id"] == currentStateId);
              final bool isValidDistrict = currentFilteredDistricts
                  .any((d) => d["id"] == currentDistrictId);

              final int? safeStateValue = isValidState ? currentStateId : null;
              final int? safeDistrictValue =
                  isValidDistrict ? currentDistrictId : null;

              if (!isValidState && currentStateId != 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    dialogSetState(() {
                      currentStateId = 0;
                      currentDistrictId = 0;
                    });
                  }
                });
              } else if (isValidState &&
                  !isValidDistrict &&
                  currentDistrictId != 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    dialogSetState(() {
                      currentDistrictId = 0;
                    });
                  }
                });
              }

              return Dialog(
                insetPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: SafeArea(
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.84,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryBlue, Color(0xff4AA3FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          child: const Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white24,
                                child: Icon(
                                  Icons.edit_note_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Edit Daily Report",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              18,
                              16,
                              18,
                              MediaQuery.of(context).viewInsets.bottom + 12,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildDialogDropdown(
                                  label: "State",
                                  icon: Icons.map_outlined,
                                  value: safeStateValue,
                                  items: stat
                                      .map(
                                        (s) => DropdownMenuItem<int>(
                                          value: s["id"],
                                          child: Text(s["name"]),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    dialogSetState(() {
                                      currentStateId = val ?? 0;
                                      currentDistrictId = 0;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildDialogDropdown(
                                  label: "District",
                                  icon: Icons.location_city_outlined,
                                  value: safeDistrictValue,
                                  items: currentFilteredDistricts
                                      .map(
                                        (d) => DropdownMenuItem<int>(
                                          value: d["id"],
                                          child: Text(d["name"]),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: currentFilteredDistricts.isNotEmpty
                                      ? (val) {
                                          dialogSetState(() {
                                            currentDistrictId = val ?? 0;
                                          });
                                        }
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                _buildDialogTextField(
                                  label: "Unbilled",
                                  controller: unbilledController,
                                  icon: Icons.pending_actions_outlined,
                                ),
                                const SizedBox(height: 12),
                                _buildDialogTextField(
                                  label: "Billed",
                                  controller: billedController,
                                  icon: Icons.receipt_long_outlined,
                                  onChanged: (_) {
                                    validateBilledAgainstUnbilled(
                                      showPopup: true,
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildDialogTextField(
                                  label: "New Customers",
                                  controller: newCustomersController,
                                  icon: Icons.person_add_alt_1_outlined,
                                ),
                                const SizedBox(height: 12),
                                _buildDialogTextField(
                                  label: "New Conversions",
                                  controller: newConversionsController,
                                  icon: Icons.trending_up_outlined,
                                  onChanged: (_) {
                                    validateConversionAgainstNewCustomers(
                                      showPopup: true,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    side:
                                        BorderSide(color: Colors.grey.shade300),
                                    minimumSize: const Size.fromHeight(46),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: darkText,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (currentStateId == 0 ||
                                        currentDistrictId == 0) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Colors.red,
                                          content:
                                              Text("Select state & district"),
                                        ),
                                      );
                                      return;
                                    }

                                    final int unbilled =
                                        _parseInt(unbilledController.text);
                                    final int billed =
                                        _parseInt(billedController.text);
                                    final int newCustomers =
                                        _parseInt(newCustomersController.text);
                                    final int newConversions = _parseInt(
                                        newConversionsController.text);

                                    if (billed > unbilled) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Colors.red,
                                          content: Text(
                                            "Billed customer cannot be greater than unbilled customer",
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    if (newConversions > newCustomers) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Colors.red,
                                          content: Text(
                                            "New conversion cannot be greater than new customers",
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    final updatedData = {
                                      "state": currentStateId,
                                      "district": currentDistrictId,
                                      "unbilled": unbilled,
                                      "billed": billed,
                                      "new_customers": newCustomers,
                                      "new_conversions": newConversions,
                                    };

                                    unbilledController.removeListener(() {});
                                    newCustomersController
                                        .removeListener(() {});

                                    Navigator.pop(context);

                                    showDialog(
                                      context: outerContext,
                                      barrierDismissible: false,
                                      builder: (_) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );

                                    final success = await updateReport(
                                        reportId, updatedData);

                                    if (Navigator.of(outerContext,
                                            rootNavigator: true)
                                        .canPop()) {
                                      Navigator.of(outerContext,
                                              rootNavigator: true)
                                          .pop();
                                    }

                                    messenger.showSnackBar(
                                      SnackBar(
                                        backgroundColor:
                                            success ? Colors.green : Colors.red,
                                        content: Text(
                                          success
                                              ? "Updated successfully"
                                              : "Update failed",
                                        ),
                                      ),
                                    );

                                    if (success) {
                                      await refreshReports();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    elevation: 0,
                                    minimumSize: const Size.fromHeight(46),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    "Update",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
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
                ),
              );
            },
          );
        });
  }

  Widget _buildDialogTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: darkText,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: primaryBlue, size: 20),
            hintText: "Enter $label",
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
            filled: true,
            fillColor: const Color(0xffF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: primaryBlue, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogDropdown({
    required String label,
    required IconData icon,
    required int? value,
    required List<DropdownMenuItem<int>> items,
    required Function(int?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: darkText,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xffF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButton<int>(
            isExpanded: true,
            value: value,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            hint: Row(
              children: [
                Icon(icon, size: 18, color: primaryBlue),
                const SizedBox(width: 8),
                Text(
                  "Select $label",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationBar() {
    if (totalCount == 0) return const SizedBox.shrink();

    List<int> visiblePages = [];
    if (totalPages <= 7) {
      visiblePages = List.generate(totalPages, (i) => i + 1);
    } else {
      visiblePages.add(1);
      if (currentPage > 3) visiblePages.add(-1);
      for (int i = currentPage - 1; i <= currentPage + 1; i++) {
        if (i > 1 && i < totalPages) visiblePages.add(i);
      }
      if (currentPage < totalPages - 2) visiblePages.add(-2);
      visiblePages.add(totalPages);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: totalPages > 1 ? 12 : 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total: $totalCount reports",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Page $currentPage / $totalPages",
                    style: const TextStyle(
                      fontSize: 12,
                      color: primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildNavButton(
                  icon: Icons.chevron_left_rounded,
                  enabled: currentPage > 1,
                  onTap: () => loadPage(currentPage - 1),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: visiblePages.map((page) {
                        if (page < 0) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              "...",
                              style: TextStyle(
                                color: subText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }

                        final isActive = page == currentPage;
                        return GestureDetector(
                          onTap: isActive ? null : () => loadPage(page),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? primaryBlue
                                  : const Color(0xffF3F6FB),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: primaryBlue.withOpacity(0.25),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                "$page",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: isActive ? Colors.white : darkText,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildNavButton(
                  icon: Icons.chevron_right_rounded,
                  enabled: currentPage < totalPages,
                  onTap: () => loadPage(currentPage + 1),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: enabled ? primaryBlue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? Colors.white : Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff1677FF), Color(0xff4AA3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sales Daily Reports",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Professional daily report overview",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _topMetric(
                  title: "Total Reports",
                  value: totalCount.toString(),
                  icon: Icons.description_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _topMetric(
                  title: "Current Page",
                  value: currentPage.toString(),
                  icon: Icons.layers_outlined,
                ),
              ),
            ],
          ),
          if (startDate != null || endDate != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_alt_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getFilterText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _topMetric({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> item, int index) {
    final createdAt = item['created_at'] != null
        ? DateTime.tryParse(item['created_at'].toString())
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffEEF2F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff1677FF), Color(0xff46A4FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    "${(currentPage - 1) * itemsPerPage + index + 1}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['team_name']?.toString().isNotEmpty == true
                        ? item['team_name'].toString()
                        : "Daily Report",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => showEditDialog(item),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 15,
                          color: Colors.white,
                        ),
                        SizedBox(width: 5),
                        Text(
                          "Edit",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              children: [
                if (createdAt != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMM yyyy').format(createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: darkText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (createdAt != null) const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _infoTile(
                        "State",
                        item['state_name']?.toString() ?? "-",
                        Icons.map_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _infoTile(
                        "District",
                        item['district_name']?.toString() ?? "-",
                        Icons.location_city_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _metricBox(
                        "Unbilled",
                        item['unbilled']?.toString() ?? "0",
                        icon: Icons.pending_actions_outlined,
                        valueColor: warningOrange,
                        cardColor: const Color(0xffFFF8EB),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _metricBox(
                        "Billed",
                        item['billed']?.toString() ?? "0",
                        icon: Icons.receipt_long_outlined,
                        valueColor: successGreen,
                        cardColor: const Color(0xffEEFDF3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _metricBox(
                        "New Customers",
                        item['new_customers']?.toString() ?? "0",
                        icon: Icons.person_add_alt_1_outlined,
                        valueColor: primaryBlue,
                        cardColor: const Color(0xffEFF6FF),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _metricBox(
                        "New Conversions",
                        item['new_conversions']?.toString() ?? "0",
                        icon: Icons.trending_up_outlined,
                        valueColor: successGreen,
                        cardColor: const Color(0xffEEFDF3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 18,
              color: primaryBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBox(
    String title,
    String value, {
    required IconData icon,
    required Color valueColor,
    required Color cardColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: valueColor),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: darkText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 86,
              width: 86,
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 42,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              startDate != null || endDate != null
                  ? "No reports found for selected date range"
                  : "No reports found",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              startDate != null || endDate != null
                  ? "Try clearing the current filter and refresh the list."
                  : "Daily reports will appear here once data is available.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            if (startDate != null || endDate != null)
              OutlinedButton.icon(
                onPressed: _clearDateFilter,
                icon: const Icon(Icons.clear),
                label: const Text("Clear Filter"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryBlue,
                  side: const BorderSide(color: primaryBlue),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getFilterText() {
    if (startDate != null && endDate != null) {
      return "${DateFormat('dd MMM yyyy').format(startDate!)} - ${DateFormat('dd MMM yyyy').format(endDate!)}";
    } else if (startDate != null) {
      return "From ${DateFormat('dd MMM yyyy').format(startDate!)}";
    } else if (endDate != null) {
      return "Until ${DateFormat('dd MMM yyyy').format(endDate!)}";
    }
    return "All reports";
  }

  Widget buildInfoRow(
    String label,
    String value, {
    IconData? icon,
    Color valueColor = Colors.black87,
    FontWeight valueWeight = FontWeight.normal,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: icon != null ? 100 : 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: valueWeight,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      toolbarHeight: 68,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
        onPressed: _navigateBack,
      ),
      titleSpacing: 0,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sales Daily Reports",
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2),
          Text(
            "Track and manage daily report entries",
            style: TextStyle(
              color: Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      flexibleSpace: Container(),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_month_rounded, color: Colors.black),
          onPressed: _selectDateRange,
          tooltip: 'Filter by date range',
        ),
        if (startDate != null || endDate != null)
          IconButton(
            icon: const Icon(Icons.clear_rounded, color: Colors.black),
            onPressed: _clearDateFilter,
            tooltip: 'Clear date filter',
          ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.black),
          onPressed: refreshReports,
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF4F8FC),
        appBar: _buildAppBar(),
        body: RefreshIndicator(
          color: primaryBlue,
          onRefresh: refreshReports,
          child: isLoading && reportsList.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: primaryBlue),
                )
              : reportsList.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                            itemCount: reportsList.length,
                            itemBuilder: (context, index) {
                              final item = reportsList[index];
                              return _buildReportCard(item, index);
                            },
                          ),
                        ),
                        if (isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: primaryBlue,
                              ),
                            ),
                          )
                        else
                          _buildPaginationBar(),
                      ],
                    ),
        ),
      ),
    );
  }
}
