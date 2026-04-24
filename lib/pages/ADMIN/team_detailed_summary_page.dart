import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:beposoft/pages/api.dart';

class TeamDetailedSummaryPage extends StatefulWidget {
  final int teamId;
  final String teamName;
  final DateTime startDate;
  final DateTime endDate;

  const TeamDetailedSummaryPage({
    Key? key,
    required this.teamId,
    required this.teamName,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  State<TeamDetailedSummaryPage> createState() =>
      _TeamDetailedSummaryPageState();
}

class _TeamDetailedSummaryPageState extends State<TeamDetailedSummaryPage> {
  bool isLoading = true;

  Map<String, dynamic> teamInfo = {};
  Map<String, dynamic> summary = {};
  List<Map<String, dynamic>> members = [];

  DateTimeRange? selectedRange;
  String fromDate = "";
  String toDate = "";

  int totalCount = 0;
  String? nextUrl;
  String? previousUrl;
  int currentPage = 1;
  int pageSize = 10;

  bool showFullHourlyTeam = false;
  Set<int> expandedMemberHourly = {};

  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> staffList = [];
  List<Map<String, dynamic>> stateList = [];
  List<Map<String, dynamic>> districtList = [];

  Map<String, dynamic>? selectedStaff;
  Map<String, dynamic>? selectedState;
  Map<String, dynamic>? selectedDistrict;
  Map<String, dynamic>? selectedInvoice;

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();

    selectedRange = DateTimeRange(
      start: DateTime(
        widget.startDate.year,
        widget.startDate.month,
        widget.startDate.day,
      ),
      end: DateTime(
        widget.endDate.year,
        widget.endDate.month,
        widget.endDate.day,
      ),
    );

    loadFilterData();
    fetchTeamDetailedSummary(page: 1);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadFilterData() async {
    await Future.wait([
      getStaffs(),
      getStates(),
    ]);
  }

  Future<void> getStaffs() async {
    try {
      final token = await getTokenFromPrefs();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$api/api/staffs/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("GET STAFFS STATUS: ${response.statusCode}");
      print("GET STAFFS BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List data = [];
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded['data'] != null) {
          data = decoded['data'];
        } else if (decoded is Map && decoded['results'] != null) {
          data = decoded['results'];
        }

        if (!mounted) return;
        setState(() {
          staffList = List<Map<String, dynamic>>.from(
            data.map((e) => {
                  'id': e['id'],
                  'name': (e['name'] ??
                          e['staff_name'] ??
                          e['username'] ??
                          e['full_name'] ??
                          '')
                      .toString(),
                }),
          );
        });
      }
    } catch (e) {
      print("GET STAFFS ERROR: $e");
    }
  }

  Future<void> getStates() async {
    try {
      final token = await getTokenFromPrefs();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("GET STATES STATUS: ${response.statusCode}");
      print("GET STATES BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List data = [];
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded['data'] != null) {
          data = decoded['data'];
        } else if (decoded is Map && decoded['results'] != null) {
          data = decoded['results'];
        }

        if (!mounted) return;
        setState(() {
          stateList = List<Map<String, dynamic>>.from(
            data.map((e) => {
                  'id': e['id'],
                  'name': (e['name'] ?? '').toString(),
                }),
          );
        });
      }
    } catch (e) {
      print("GET STATES ERROR: $e");
    }
  }

Future<void> getDistricts(int stateId) async {
  try {
    final token = await getTokenFromPrefs();
    if (token == null) return;

    final selectedStateName =
        (selectedState?['name'] ?? '').toString().trim().toLowerCase();

    final response = await http.get(
      Uri.parse('$api/api/districts/add/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("GET DISTRICTS STATUS: ${response.statusCode}");
    print("GET DISTRICTS BODY: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      List data = [];
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded['data'] != null) {
        data = decoded['data'];
      } else if (decoded is Map && decoded['results'] != null) {
        data = decoded['results'];
      }

      if (data.isNotEmpty) {
        print("DISTRICT SAMPLE ITEM: ${data.first}");
      }

      final filteredDistricts = data.where((e) {
        int? districtStateId;
        String districtStateName = "";

        if (e['state_id'] != null) {
          districtStateId = int.tryParse(e['state_id'].toString());
        }

        if (districtStateId == null && e['state'] is int) {
          districtStateId = e['state'];
        }

        if (districtStateId == null && e['state'] is String) {
          districtStateId = int.tryParse(e['state'].toString());
        }

        if (e['state'] is Map) {
          final stateMap = e['state'] as Map<String, dynamic>;

          districtStateId ??= int.tryParse(
            (stateMap['id'] ?? stateMap['state_id'] ?? '').toString(),
          );

          districtStateName = (stateMap['name'] ?? stateMap['state_name'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
        }

        if (districtStateName.isEmpty) {
          districtStateName = (e['state_name'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
        }

        final matchesId = districtStateId == stateId;
        final matchesName = districtStateName.isNotEmpty &&
            districtStateName == selectedStateName;

        return matchesId || matchesName;
      }).toList();

      print("SELECTED STATE ID: $stateId");
      print("SELECTED STATE NAME: $selectedStateName");
      print("FILTERED DISTRICT COUNT: ${filteredDistricts.length}");

      if (!mounted) return;
      setState(() {
        districtList = List<Map<String, dynamic>>.from(
          filteredDistricts.map((e) => {
                'id': e['id'],
                'name': (e['name'] ?? e['district_name'] ?? '')
                    .toString(),
              }),
        );
      });
    }
  } catch (e) {
    print("GET DISTRICTS ERROR: $e");
  }
}

Future<List<Map<String, dynamic>>> searchInvoices(String filter) async {
  try {
    final token = await getTokenFromPrefs();
    if (token == null) return [];

    String? url = Uri.parse('$api/api/orders/').replace(
      queryParameters: {
        'page': '1',
        if (filter.trim().isNotEmpty) 'search': filter.trim(),
      },
    ).toString();

    final Map<String, Map<String, dynamic>> uniqueInvoices = {};
    int pageCount = 0;
    const int maxPages = 20; // safety limit

    while (url != null && url.isNotEmpty && pageCount < maxPages) {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("SEARCH INVOICE URL: $url");
      print("SEARCH INVOICE STATUS: ${response.statusCode}");

      if (response.statusCode != 200) {
        break;
      }

      final decoded = jsonDecode(response.body);
      final List innerResults =
          decoded['results']?['results'] as List<dynamic>? ?? [];

      for (final item in innerResults) {
        if (item == null) continue;

        final invoiceValue = (item['invoice'] ?? '').toString().trim();
        if (invoiceValue.isEmpty) continue;

        if (filter.trim().isEmpty ||
            invoiceValue.toLowerCase().contains(filter.trim().toLowerCase())) {
          uniqueInvoices[invoiceValue] = {
            'id': invoiceValue,
            'name': invoiceValue,
          };
        }
      }

      final next = decoded['next'];
      url = (next != null && next.toString().isNotEmpty)
          ? next.toString()
          : null;

      pageCount++;
    }

    final invoices = uniqueInvoices.values.toList()
      ..sort((a, b) => (b['name'] ?? '')
          .toString()
          .compareTo((a['name'] ?? '').toString()));

    return invoices;
  } catch (e) {
    print("SEARCH INVOICE ERROR: $e");
    return [];
  }
}

  Future<void> pickDateRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 1),
      initialDateRange: selectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF02347C),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedRange = DateTimeRange(
          start: DateTime(
            picked.start.year,
            picked.start.month,
            picked.start.day,
          ),
          end: DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
          ),
        );
        currentPage = 1;
      });

      await fetchTeamDetailedSummary(page: 1);
    }
  }

  Map<String, String> _buildQueryParams({required int page}) {
    final Map<String, String> queryParams = {
      'page': page.toString(),
    };

    if (selectedRange != null) {
      queryParams['start_date'] =
          DateFormat('yyyy-MM-dd').format(selectedRange!.start);
      queryParams['end_date'] =
          DateFormat('yyyy-MM-dd').format(selectedRange!.end);
    } else {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      queryParams['start_date'] = today;
      queryParams['end_date'] = today;
    }

    if (searchController.text.trim().isNotEmpty) {
      queryParams['search'] = searchController.text.trim();
    }

    if (selectedStaff != null) {
      queryParams['staff_id'] = selectedStaff!['id'].toString();
    }

    if (selectedState != null) {
      queryParams['state_id'] = selectedState!['id'].toString();
    }

    if (selectedDistrict != null) {
      queryParams['district_id'] = selectedDistrict!['id'].toString();
    }

    if (selectedInvoice != null &&
        (selectedInvoice!['name'] ?? '').toString().trim().isNotEmpty) {
      queryParams['invoice_id'] = selectedInvoice!['name'].toString().trim();
    }

    return queryParams;
  }

  Future<void> fetchTeamDetailedSummary({int page = 1}) async {
    final token = await getTokenFromPrefs();
    if (token == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final queryParams = _buildQueryParams(page: page);

      final url = Uri.parse(
        '$api/api/team/detailed/summary/${widget.teamId}/',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("TEAM DETAILED URL: $url");
      print("TEAM DETAILED STATUS: ${response.statusCode}");
      print("TEAM DETAILED BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final results = Map<String, dynamic>.from(decoded['results'] ?? {});
        final team = Map<String, dynamic>.from(results['team'] ?? {});
        final summ = Map<String, dynamic>.from(results['summary'] ?? {});
        final List memberList = results['members'] ?? [];

        if (!mounted) return;
        setState(() {
          teamInfo = team;
          summary = summ;
          members = List<Map<String, dynamic>>.from(
            memberList.map((e) => Map<String, dynamic>.from(e)),
          );

          totalCount = decoded['count'] ?? 0;
          nextUrl = decoded['next'];
          previousUrl = decoded['previous'];
          currentPage = page;

          fromDate = queryParams['start_date'] ?? "";
          toDate = queryParams['end_date'] ?? "";
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          teamInfo = {};
          summary = {};
          members = [];
          totalCount = 0;
          nextUrl = null;
          previousUrl = null;
          isLoading = false;
        });
      }
    } catch (e) {
      print("TEAM DETAILED ERROR: $e");
      if (!mounted) return;
      setState(() {
        teamInfo = {};
        summary = {};
        members = [];
        totalCount = 0;
        nextUrl = null;
        previousUrl = null;
        isLoading = false;
      });
    }
  }

  void applyFilters() {
    setState(() {
      currentPage = 1;
      showFullHourlyTeam = false;
      expandedMemberHourly.clear();
    });
    fetchTeamDetailedSummary(page: 1);
  }

  void clearFilters() {
    setState(() {
      searchController.clear();

      selectedStaff = null;
      selectedState = null;
      selectedDistrict = null;
      selectedInvoice = null;

      districtList = [];

      currentPage = 1;
      showFullHourlyTeam = false;
      expandedMemberHourly.clear();
    });
    fetchTeamDetailedSummary(page: 1);
  }

  Widget _buildMetricTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xffE6ECF5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF02347C),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSearchableDropdown({
    required String hint,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic>? selectedItem,
    required Function(Map<String, dynamic>?) onChanged,
  }) {
    return DropdownSearch<Map<String, dynamic>>(
      items: items,
      selectedItem: selectedItem,
      itemAsString: (item) => item['name'].toString(),
      compareFn: (a, b) => a['id'] == b['id'],
      onChanged: onChanged,
      popupProps: const PopupProps.menu(
        showSearchBox: true,
        fit: FlexFit.loose,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: "Search...",
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xffF7F9FC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xffE6ECF5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xffE6ECF5)),
          ),
        ),
      ),
    );
  }

  Widget buildInvoiceDropdown() {
    return DropdownSearch<Map<String, dynamic>>(
      selectedItem: selectedInvoice,
      itemAsString: (item) => item['name'].toString(),
      compareFn: (a, b) => a['id'] == b['id'],
      onChanged: (value) {
        setState(() {
          selectedInvoice = value;
        });
      },
      asyncItems: (String filter) => searchInvoices(filter),
      popupProps:  PopupProps.menu(
        showSearchBox: true,
        fit: FlexFit.loose,
        emptyBuilder: (context, searchEntry) => Padding(
          padding: EdgeInsets.all(12),
          child: Text("No invoice found"),
        ),
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: "Search invoice...",
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: "Select Invoice",
          filled: true,
          fillColor: const Color(0xffF7F9FC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xffE6ECF5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xffE6ECF5)),
          ),
        ),
      ),
    );
  }

  Widget buildFiltersCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xffE6ECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Filters",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF02347C),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Search",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xffF7F9FC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffE6ECF5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffE6ECF5)),
              ),
            ),
            onSubmitted: (_) => applyFilters(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: buildSearchableDropdown(
                  hint: "Select Staff",
                  items: staffList,
                  selectedItem: selectedStaff,
                  onChanged: (value) {
                    setState(() {
                      selectedStaff = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: buildSearchableDropdown(
                  hint: "Select State",
                  items: stateList,
                  selectedItem: selectedState,
                  onChanged: (value) async {
                    setState(() {
                      selectedState = value;
                      selectedDistrict = null;
                      districtList = [];
                    });

                    if (value != null) {
                      await getDistricts(value['id']);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: buildSearchableDropdown(
                  hint: "Select District",
                  items: districtList,
                  selectedItem: selectedDistrict,
                  onChanged: (value) {
                    setState(() {
                      selectedDistrict = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: buildInvoiceDropdown(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF02347C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Apply Filters"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: clearFilters,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF02347C),
                    side: const BorderSide(color: Color(0xFF02347C)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Clear"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildTopSummaryCard() {
    final teamName =
        (teamInfo['team_name'] ?? widget.teamName).toString().toUpperCase();

    final totalUnbilled = summary['total_unbilled'] ?? 0;
    final totalBilled =
        double.tryParse(summary['total_bill'].toString()) ?? 0.0;
    final newCustomers = summary['new_customers'] ?? 0;
    final newConversions = summary['new_conversions'] ?? 0;
    final totalInvoices = summary['billing'] ?? 0;
    final totalAmount = double.tryParse(summary['volume'].toString()) ?? 0.0;
    final totalCallDuration =
        double.tryParse(summary['total_call_duration'].toString()) ?? 0.0;
    final callDurationAverage =
        double.tryParse(summary['call_duration_average'].toString()) ?? 0.0;
    final callDurationPercentage =
        double.tryParse(summary['call_duration_percentage_8hrs'].toString()) ??
            0.0;
    final activeCount = summary['active_count'] ?? 0;
    final productiveCount = summary['productive_count'] ?? 0;

    final hourlyDurations =
        Map<String, dynamic>.from(summary['hourly_durations'] ?? {});

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                colors: [Color(0xFF02347C), Color(0xFF82E49D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: teamName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: " ($fromDate to $toDate)",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: pickDateRange,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          _buildMetricTile("Total Unbilled", "$totalUnbilled"),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        "Total Billed",
                        "₹${totalBilled.toStringAsFixed(1)}",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile("New Customers", "$newCustomers"),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child:
                          _buildMetricTile("New Conversion", "$newConversions"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child:
                          _buildMetricTile("Total Invoices", "$totalInvoices"),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        "Total Amount",
                        "₹${totalAmount.toStringAsFixed(1)}",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        "Total Call Duration",
                        "${totalCallDuration.toStringAsFixed(2)} min",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        "Call Duration Avg",
                        "${callDurationAverage.toStringAsFixed(2)} min",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        "Call Duration %",
                        "${callDurationPercentage.toStringAsFixed(2)}%",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile("Active Count", "$activeCount"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        "Productive Count",
                        "$productiveCount",
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                if (hourlyDurations.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffF7F9FC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffE6ECF5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Hourly Durations",
                          style: TextStyle(
                            color: Color(0xFF02347C),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...hourlyDurations.entries
                            .take(
                                showFullHourlyTeam ? hourlyDurations.length : 2)
                            .map(
                              (entry) => Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xffE6ECF5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                          color: Color(0xFF02347C),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "${(double.tryParse(entry.value.toString()) ?? 0).toStringAsFixed(2)} min",
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        if (hourlyDurations.length > 2)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  showFullHourlyTeam = !showFullHourlyTeam;
                                });
                              },
                              child: Center(
                                child: Text(
                                  showFullHourlyTeam ? "See Less" : "See More",
                                  style: const TextStyle(
                                    color: Color(0xFF02347C),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMemberCard(Map<String, dynamic> member) {
    final int staffId = member['staff_id'] ?? 0;
    final String memberName =
        (member['staff_name'] ?? '').toString().toUpperCase();
    final Map<String, dynamic> memberSummary =
        Map<String, dynamic>.from(member['summary'] ?? {});

    final totalUnbilled = memberSummary['total_unbilled'] ?? 0;
    final totalBilled =
        double.tryParse(memberSummary['total_bill'].toString()) ?? 0.0;
    final newCustomers = memberSummary['new_customers'] ?? 0;
    final newConversions = memberSummary['new_conversions'] ?? 0;
    final totalInvoices = memberSummary['billing'] ?? 0;
    final totalAmount =
        double.tryParse(memberSummary['volume'].toString()) ?? 0.0;
    final totalCallDuration =
        double.tryParse(memberSummary['total_call_duration'].toString()) ?? 0.0;
    final callDurationAverage =
        double.tryParse(memberSummary['call_duration_average'].toString()) ??
            0.0;
    final callDurationPercentage = double.tryParse(
          memberSummary['call_duration_percentage_8hrs'].toString(),
        ) ??
        0.0;
    final activeCount = memberSummary['active_count'] ?? 0;
    final productiveCount = memberSummary['productive_count'] ?? 0;

    final hourlyDurations =
        Map<String, dynamic>.from(memberSummary['hourly_durations'] ?? {});

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF60A5FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Text(
              memberName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          _buildMetricTile("Total Unbilled", "$totalUnbilled"),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        "Total Billed",
                        "₹${totalBilled.toStringAsFixed(1)}",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile("New Customers", "$newCustomers"),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child:
                          _buildMetricTile("New Conversion", "$newConversions"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child:
                          _buildMetricTile("Total Invoices", "$totalInvoices"),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        "Total Amount",
                        "₹${totalAmount.toStringAsFixed(1)}",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        "Total Call Duration",
                        "${totalCallDuration.toStringAsFixed(2)} min",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        "Call Duration Avg",
                        "${callDurationAverage.toStringAsFixed(2)} min",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        "Call Duration %",
                        "${callDurationPercentage.toStringAsFixed(2)}%",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile("Active Count", "$activeCount"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        "Productive Count",
                        "$productiveCount",
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                if (hourlyDurations.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffF7F9FC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffE6ECF5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Hourly Durations",
                          style: TextStyle(
                            color: Color(0xFF02347C),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...hourlyDurations.entries
                            .take(
                              expandedMemberHourly.contains(staffId)
                                  ? hourlyDurations.length
                                  : 2,
                            )
                            .map(
                              (entry) => Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xffE6ECF5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                          color: Color(0xFF02347C),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "${(double.tryParse(entry.value.toString()) ?? 0).toStringAsFixed(2)} min",
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        if (hourlyDurations.length > 2)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  if (expandedMemberHourly.contains(staffId)) {
                                    expandedMemberHourly.remove(staffId);
                                  } else {
                                    expandedMemberHourly.add(staffId);
                                  }
                                });
                              },
                              child: Center(
                                child: Text(
                                  expandedMemberHourly.contains(staffId)
                                      ? "See Less"
                                      : "See More",
                                  style: const TextStyle(
                                    color: Color(0xFF02347C),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPaginationControls() {
    final totalPages = (totalCount / pageSize).ceil();

    if (totalPages <= 1) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: previousUrl != null && currentPage > 1
                ? () {
                    fetchTeamDetailedSummary(page: currentPage - 1);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF02347C),
              foregroundColor: Colors.white,
            ),
            child: const Text("Previous"),
          ),
          Text(
            "Page $currentPage of $totalPages",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton(
            onPressed: nextUrl != null && currentPage < totalPages
                ? () {
                    fetchTeamDetailedSummary(page: currentPage + 1);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF02347C),
              foregroundColor: Colors.white,
            ),
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text(
          "Team Detailed Summary",
          style: TextStyle(fontSize: 20),
        ),
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => fetchTeamDetailedSummary(page: currentPage),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  buildFiltersCard(),
                  buildTopSummaryCard(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 8, 14, 4),
                    child: Text(
                      "Member Wise Summary",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  ...members.map((member) => buildMemberCard(member)).toList(),
                  buildPaginationControls(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}