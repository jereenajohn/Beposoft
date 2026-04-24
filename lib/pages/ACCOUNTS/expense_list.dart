import 'dart:async';
import 'dart:convert';

import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class expence_list extends StatefulWidget {
  const expence_list({super.key});

  @override
  State<expence_list> createState() => _expence_listState();
}

class _expence_listState extends State<expence_list> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;

  final String apiBaseUrl = "https://bepocart.in";

  bool _isLoading = false;
  bool _isFirstLoad = true;
  bool _isLoadingMore = false;
  bool _hasNextPage = true;

  int _currentPage = 1;
  int _totalCount = 0;

  String? token;

  List<ExpenseItem> expenseList = [];

  ExpenseSummary summary = ExpenseSummary.empty();
  Map<String, ExpenseTypeSummary> summaryByType = {};

  ExpenseFilters filters = ExpenseFilters();

  List<DropdownOption> _purposeOptions = [];
  List<DropdownOption> _companyOptions = [];
  List<DropdownOption> _bankOptions = [];
  List<DropdownOption> _addedByOptions = [];
  List<DropdownOption> _assetTypeOptions = const [
    DropdownOption(id: "assets", label: "Assets"),
    DropdownOption(id: "expenses", label: "Expenses"),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTokenAndFetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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


  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? prefs.getString("access");

    _searchController.text = filters.search;

    await _loadDropdownData();
    await fetchExpenses(reset: true);
  }

  Future<void> _loadDropdownData() async {
    await Future.wait([
      _fetchPurposeOptions(),
      _fetchCompanyOptions(),
      _fetchBankOptions(),
      _fetchAddedByOptions(),
    ]);
  }

  Future<void> _fetchPurposeOptions() async {
    if (token == null || token!.isEmpty) return;

    try {
      final uri = Uri.parse("$apiBaseUrl/apis/add/purpose/");
      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          final items = decoded
              .map((e) => PurposeOption.fromJson(e as Map<String, dynamic>))
              .where((e) => e.name.trim().isNotEmpty)
              .map(
                (e) => DropdownOption(
                  id: e.id.toString(),
                  label: e.name.trim(),
                ),
              )
              .toList();

          if (mounted) {
            setState(() {
              _purposeOptions = items;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("PURPOSE DROPDOWN ERROR: $e");
    }
  }

  Future<void> _fetchCompanyOptions() async {
    if (token == null || token!.isEmpty) return;

    try {
      final uri = Uri.parse("$apiBaseUrl/api/company/data/");
      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> rawList =
            decoded["data"] is List ? decoded["data"] as List : [];

        final items = rawList
            .map((e) => CompanyOption.fromJson(e as Map<String, dynamic>))
            .where((e) => e.name.trim().isNotEmpty)
            .map(
              (e) => DropdownOption(
                id: e.id.toString(),
                label: e.name.trim(),
              ),
            )
            .toList();

        if (mounted) {
          setState(() {
            _companyOptions = items;
          });
        }
      }
    } catch (e) {
      debugPrint("COMPANY DROPDOWN ERROR: $e");
    }
  }

  Future<void> _fetchBankOptions() async {
    if (token == null || token!.isEmpty) return;

    try {
      final uri = Uri.parse("$apiBaseUrl/api/banks/");
      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> rawList =
            decoded["data"] is List ? decoded["data"] as List : [];

        final items = rawList
            .map((e) => BankOption.fromJson(e as Map<String, dynamic>))
            .where((e) => e.name.trim().isNotEmpty)
            .map(
              (e) => DropdownOption(
                id: e.id.toString(),
                label: e.name.trim(),
              ),
            )
            .toList();

        if (mounted) {
          setState(() {
            _bankOptions = items;
          });
        }
      }
    } catch (e) {
      debugPrint("BANK DROPDOWN ERROR: $e");
    }
  }

  Future<void> _fetchAddedByOptions() async {
    if (token == null || token!.isEmpty) return;

    try {
      final uri = Uri.parse("$apiBaseUrl/api/staffs/");
      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> rawList =
            decoded["data"] is List ? decoded["data"] as List : [];

        final staffItems = rawList
            .map((e) => StaffOption.fromJson(e as Map<String, dynamic>))
            .where((e) => e.name.trim().isNotEmpty)
            .toList();

        final Map<String, DropdownOption> uniqueMap = {};
        for (final item in staffItems) {
          final key = item.name.trim().toLowerCase();
          uniqueMap[key] = DropdownOption(
            id: item.id.toString(),
            label: item.name.trim(),
          );
        }

        final items = uniqueMap.values.toList()
          ..sort(
            (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
          );

        if (mounted) {
          setState(() {
            _addedByOptions = items;
          });
        }
      }
    } catch (e) {
      debugPrint("ADDED BY DROPDOWN ERROR: $e");
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_isLoading &&
        _hasNextPage) {
      fetchExpenses();
    }
  }

  Future<void> fetchExpenses({bool reset = false}) async {
    if (token == null || token!.isEmpty) return;

    if (reset) {
      setState(() {
        _isLoading = true;
        _isFirstLoad = true;
        _currentPage = 1;
        _hasNextPage = true;
        expenseList.clear();
      });
    } else {
      if (!_hasNextPage) return;
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final queryParams = <String, String>{
        "page": _currentPage.toString(),
      };

      if (filters.search.trim().isNotEmpty) {
        queryParams["search"] = filters.search.trim();
      }
      if (filters.startDate.trim().isNotEmpty) {
        queryParams["start_date"] = filters.startDate.trim();
      }
      if (filters.endDate.trim().isNotEmpty) {
        queryParams["end_date"] = filters.endDate.trim();
      }
      if (filters.purpose.trim().isNotEmpty) {
        queryParams["purpose"] = filters.purpose.trim();
      }
      if (filters.purposeId.trim().isNotEmpty) {
        queryParams["purpose_id"] = filters.purposeId.trim();
      }
      if (filters.expenseType.trim().isNotEmpty) {
        queryParams["expense_type"] = filters.expenseType.trim().toLowerCase();
      }
      if (filters.company.trim().isNotEmpty) {
        queryParams["company"] = filters.company.trim();
      }
      if (filters.companyId.trim().isNotEmpty) {
        queryParams["company_id"] = filters.companyId.trim();
      }
      if (filters.bank.trim().isNotEmpty) {
        queryParams["bank"] = filters.bank.trim();
      }
      if (filters.bankId.trim().isNotEmpty) {
        queryParams["bank_id"] = filters.bankId.trim();
      }
      if (filters.addedBy.trim().isNotEmpty) {
        queryParams["added_by"] = filters.addedBy.trim();
      }
      if (filters.categoryId.trim().isNotEmpty) {
        queryParams["category_id"] = filters.categoryId.trim();
      }
      if (filters.assetTypes.trim().isNotEmpty) {
        queryParams["asset_types"] = filters.assetTypes.trim();
      }
      if (filters.minAmount.trim().isNotEmpty) {
        queryParams["min_amount"] = filters.minAmount.trim();
      }
      if (filters.maxAmount.trim().isNotEmpty) {
        queryParams["max_amount"] = filters.maxAmount.trim();
      }
      if (filters.ordering.trim().isNotEmpty) {
        queryParams["ordering"] = filters.ordering.trim();
      }

      final uri = Uri.parse("$apiBaseUrl/api/expense/get/data/")
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      debugPrint("EXPENSE URL: $uri");
      debugPrint("EXPENSE STATUS: ${response.statusCode}");
      debugPrint("EXPENSE RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final int count = _toInt(decoded["count"]);
        final String? nextUrl = decoded["next"]?.toString();

        final Map<String, dynamic> outerResults =
            decoded["results"] is Map<String, dynamic>
                ? decoded["results"] as Map<String, dynamic>
                : {};

        final Map<String, dynamic> summaryMap =
            outerResults["summary"] is Map<String, dynamic>
                ? outerResults["summary"] as Map<String, dynamic>
                : {};

        final Map<String, dynamic> summaryByTypeMap =
            outerResults["summary_by_type"] is Map<String, dynamic>
                ? outerResults["summary_by_type"] as Map<String, dynamic>
                : {};

        final List<dynamic> listRaw = outerResults["results"] is List
            ? outerResults["results"] as List
            : [];

        final List<ExpenseItem> fetchedItems = listRaw
            .map((e) => ExpenseItem.fromJson(e as Map<String, dynamic>))
            .toList();

        final parsedSummary = ExpenseSummary.fromJson(summaryMap);

        final Map<String, ExpenseTypeSummary> parsedSummaryByType = {};
        summaryByTypeMap.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            parsedSummaryByType[key] = ExpenseTypeSummary.fromJson(value);
          }
        });

        setState(() {
          _totalCount = count;
          summary = parsedSummary;
          summaryByType = parsedSummaryByType;

          if (reset) {
            expenseList = fetchedItems;
          } else {
            expenseList.addAll(fetchedItems);
          }

          _hasNextPage = nextUrl != null && nextUrl.isNotEmpty;

          if (_hasNextPage) {
            _currentPage += 1;
          }

          _isLoading = false;
          _isLoadingMore = false;
          _isFirstLoad = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _isFirstLoad = false;
        });

        _showSnackBar("Failed to fetch expenses (${response.statusCode})");
      }
    } catch (e) {
      debugPrint("EXPENSE ERROR: $e");
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _isFirstLoad = false;
      });
      _showSnackBar("Something went wrong while fetching expenses");
    }
  }

  Future<void> _refresh() async {
    await fetchExpenses(reset: true);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      filters.search = value.trim();
      fetchExpenses(reset: true);
    });
  }

  void _clearAllFilters() {
    setState(() {
      filters = ExpenseFilters();
      _searchController.clear();
    });
    fetchExpenses(reset: true);
  }

  Future<void> _pickDate({
    required BuildContext context,
    required bool isStartDate,
    required ValueChanged<String> onDateSelected,
    String? initialDateString,
  }) async {
    DateTime initialDate = DateTime.now();

    if (initialDateString != null && initialDateString.isNotEmpty) {
      try {
        initialDate = DateTime.parse(initialDateString);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      onDateSelected(DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  Future<DropdownOption?> _showSearchableDropdown({
    required String title,
    required List<DropdownOption> items,
    DropdownOption? selectedItem,
  }) async {
    return showModalBottomSheet<DropdownOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final TextEditingController searchController = TextEditingController();
        List<DropdownOption> filteredItems = List.from(items);

        return StatefulBuilder(
          builder: (context, setModalState) {
            void filterList(String value) {
              setModalState(() {
                filteredItems = items.where((item) {
                  return item.label.toLowerCase().contains(value.toLowerCase());
                }).toList();
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.80,
              decoration: const BoxDecoration(
                color: Color(0xfff5f7fb),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff172033),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: TextField(
                        controller: searchController,
                        onChanged: filterList,
                        decoration: InputDecoration(
                          hintText: "Search $title",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xff1f6feb),
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filteredItems.isEmpty
                          ? Center(
                              child: Text(
                                "No data found",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredItems.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                final bool isSelected =
                                    selectedItem?.id == item.id &&
                                    selectedItem?.label == item.label;

                                return ListTile(
                                  title: Text(
                                    item.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xff172033),
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Color(0xff1f6feb),
                                        )
                                      : null,
                                  onTap: () {
                                    Navigator.pop(context, item);
                                  },
                                );
                              },
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

  Widget _buildSearchDropdownField({
    required String label,
    required TextEditingController nameController,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final bool hasValue = nameController.text.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _inputDecoration(label).copyWith(
          suffixIcon: hasValue
              ? IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                )
              : const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          hasValue ? nameController.text : "Select $label",
          style: TextStyle(
            color: hasValue ? const Color(0xff172033) : Colors.grey.shade600,
            fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  void _openFilterSheet() {
    final TextEditingController purposeController =
        TextEditingController(text: filters.purpose);
    final TextEditingController purposeIdController =
        TextEditingController(text: filters.purposeId);
    final TextEditingController companyController =
        TextEditingController(text: filters.company);
    final TextEditingController companyIdController =
        TextEditingController(text: filters.companyId);
    final TextEditingController bankController =
        TextEditingController(text: filters.bank);
    final TextEditingController bankIdController =
        TextEditingController(text: filters.bankId);
    final TextEditingController addedByController =
        TextEditingController(text: filters.addedBy);
    final TextEditingController categoryIdController =
        TextEditingController(text: filters.categoryId);
    final TextEditingController assetTypesController =
        TextEditingController(text: filters.assetTypes);
    final TextEditingController minAmountController =
        TextEditingController(text: filters.minAmount);
    final TextEditingController maxAmountController =
        TextEditingController(text: filters.maxAmount);

    DropdownOption? selectedPurpose = filters.purpose.isNotEmpty
        ? DropdownOption(
            id: filters.purposeId,
            label: filters.purpose,
          )
        : null;

    DropdownOption? selectedCompany = filters.company.isNotEmpty
        ? DropdownOption(
            id: filters.companyId,
            label: filters.company,
          )
        : null;

    DropdownOption? selectedBank = filters.bank.isNotEmpty
        ? DropdownOption(
            id: filters.bankId,
            label: filters.bank,
          )
        : null;

    DropdownOption? selectedAddedBy = filters.addedBy.isNotEmpty
        ? DropdownOption(
            id: "",
            label: filters.addedBy,
          )
        : null;

    DropdownOption? selectedAssetType = filters.assetTypes.isNotEmpty
        ? DropdownOption(
            id: filters.assetTypes,
            label: filters.assetTypes[0].toUpperCase() +
                filters.assetTypes.substring(1),
          )
        : null;

    String localStartDate = filters.startDate;
    String localEndDate = filters.endDate;
    String localExpenseType = filters.expenseType;
    String localOrdering = filters.ordering.isEmpty ? "-id" : filters.ordering;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Color(0xfff5f7fb),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Filter Expenses",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff172033),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              purposeController.clear();
                              purposeIdController.clear();
                              companyController.clear();
                              companyIdController.clear();
                              bankController.clear();
                              bankIdController.clear();
                              addedByController.clear();
                              categoryIdController.clear();
                              assetTypesController.clear();
                              minAmountController.clear();
                              maxAmountController.clear();

                              selectedPurpose = null;
                              selectedCompany = null;
                              selectedBank = null;
                              selectedAddedBy = null;
                              selectedAssetType = null;

                              setModalState(() {
                                localStartDate = "";
                                localEndDate = "";
                                localExpenseType = "";
                                localOrdering = "-id";
                              });
                            },
                            child: const Text("Clear"),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle("Date Range"),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _dateField(
                                    label: "From Date",
                                    value: localStartDate,
                                    onTap: () async {
                                      await _pickDate(
                                        context: context,
                                        isStartDate: true,
                                        initialDateString: localStartDate,
                                        onDateSelected: (value) {
                                          setModalState(() {
                                            localStartDate = value;
                                          });
                                        },
                                      );
                                    },
                                    onClear: () {
                                      setModalState(() {
                                        localStartDate = "";
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _dateField(
                                    label: "To Date",
                                    value: localEndDate,
                                    onTap: () async {
                                      await _pickDate(
                                        context: context,
                                        isStartDate: false,
                                        initialDateString: localEndDate,
                                        onDateSelected: (value) {
                                          setModalState(() {
                                            localEndDate = value;
                                          });
                                        },
                                      );
                                    },
                                    onClear: () {
                                      setModalState(() {
                                        localEndDate = "";
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _sectionTitle("Quick Filters"),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: localExpenseType.isEmpty
                                  ? null
                                  : localExpenseType,
                              decoration: _inputDecoration("Expense Type"),
                              items: const [
                                DropdownMenuItem(
                                  value: "miscellaneous",
                                  child: Text("Miscellaneous"),
                                ),
                                DropdownMenuItem(
                                  value: "permanent",
                                  child: Text("Permanent"),
                                ),
                                DropdownMenuItem(
                                  value: "emi",
                                  child: Text("EMI"),
                                ),
                                DropdownMenuItem(
                                  value: "cargo",
                                  child: Text("Cargo"),
                                ),
                                DropdownMenuItem(
                                  value: "purchase",
                                  child: Text("Purchase"),
                                ),
                                DropdownMenuItem(
                                  value: "others",
                                  child: Text("Others"),
                                ),
                              ],
                              onChanged: (value) {
                                setModalState(() {
                                  localExpenseType =
                                      (value ?? "").trim().toLowerCase();
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: localOrdering,
                              decoration: _inputDecoration("Ordering"),
                              items: const [
                                DropdownMenuItem(
                                  value: "-id",
                                  child: Text("Latest First"),
                                ),
                                DropdownMenuItem(
                                  value: "id",
                                  child: Text("Oldest First"),
                                ),
                                DropdownMenuItem(
                                  value: "-expense_date",
                                  child: Text("Expense Date Desc"),
                                ),
                                DropdownMenuItem(
                                  value: "expense_date",
                                  child: Text("Expense Date Asc"),
                                ),
                                DropdownMenuItem(
                                  value: "-amount",
                                  child: Text("Amount High to Low"),
                                ),
                                DropdownMenuItem(
                                  value: "amount",
                                  child: Text("Amount Low to High"),
                                ),
                              ],
                              onChanged: (value) {
                                setModalState(() {
                                  localOrdering = value ?? "-id";
                                });
                              },
                            ),
                            const SizedBox(height: 18),
                            _sectionTitle("Amount"),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: minAmountController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: _inputDecoration("Min Amount"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: maxAmountController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: _inputDecoration("Max Amount"),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _sectionTitle("Advanced Filters"),
                            const SizedBox(height: 10),
                            _buildSearchDropdownField(
                              label: "Purpose",
                              nameController: purposeController,
                              onTap: () async {
                                final result = await _showSearchableDropdown(
                                  title: "Purpose",
                                  items: _purposeOptions,
                                  selectedItem: selectedPurpose,
                                );
                                if (result != null) {
                                  setModalState(() {
                                    selectedPurpose = result;
                                    purposeController.text = result.label;
                                    purposeIdController.text = result.id;
                                  });
                                }
                              },
                              onClear: () {
                                setModalState(() {
                                  selectedPurpose = null;
                                  purposeController.clear();
                                  purposeIdController.clear();
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildSearchDropdownField(
                              label: "Company",
                              nameController: companyController,
                              onTap: () async {
                                final result = await _showSearchableDropdown(
                                  title: "Company",
                                  items: _companyOptions,
                                  selectedItem: selectedCompany,
                                );
                                if (result != null) {
                                  setModalState(() {
                                    selectedCompany = result;
                                    companyController.text = result.label;
                                    companyIdController.text = result.id;
                                  });
                                }
                              },
                              onClear: () {
                                setModalState(() {
                                  selectedCompany = null;
                                  companyController.clear();
                                  companyIdController.clear();
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildSearchDropdownField(
                              label: "Bank",
                              nameController: bankController,
                              onTap: () async {
                                final result = await _showSearchableDropdown(
                                  title: "Bank",
                                  items: _bankOptions,
                                  selectedItem: selectedBank,
                                );
                                if (result != null) {
                                  setModalState(() {
                                    selectedBank = result;
                                    bankController.text = result.label;
                                    bankIdController.text = result.id;
                                  });
                                }
                              },
                              onClear: () {
                                setModalState(() {
                                  selectedBank = null;
                                  bankController.clear();
                                  bankIdController.clear();
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildSearchDropdownField(
                              label: "Added By",
                              nameController: addedByController,
                              onTap: () async {
                                final result = await _showSearchableDropdown(
                                  title: "Added By",
                                  items: _addedByOptions,
                                  selectedItem: selectedAddedBy,
                                );
                                if (result != null) {
                                  setModalState(() {
                                    selectedAddedBy = result;
                                    addedByController.text = result.label;
                                  });
                                }
                              },
                              onClear: () {
                                setModalState(() {
                                  selectedAddedBy = null;
                                  addedByController.clear();
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            // _buildTextField(
                            //   controller: categoryIdController,
                            //   label: "Category ID",
                            //   keyboardType: TextInputType.number,
                            // ),
                            // const SizedBox(height: 12),
                            _buildSearchDropdownField(
                              label: "Asset Types",
                              nameController: assetTypesController,
                              onTap: () async {
                                final result = await _showSearchableDropdown(
                                  title: "Asset Types",
                                  items: _assetTypeOptions,
                                  selectedItem: selectedAssetType,
                                );
                                if (result != null) {
                                  setModalState(() {
                                    selectedAssetType = result;
                                    assetTypesController.text = result.id;
                                  });
                                }
                              },
                              onClear: () {
                                setModalState(() {
                                  selectedAssetType = null;
                                  assetTypesController.clear();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 10,
                            color: Colors.black.withOpacity(0.06),
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text("Cancel"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  filters.startDate = localStartDate.trim();
                                  filters.endDate = localEndDate.trim();
                                  filters.expenseType =
                                      localExpenseType.trim().toLowerCase();
                                  filters.ordering =
                                      localOrdering.trim().isEmpty
                                      ? "-id"
                                      : localOrdering.trim();

                                  filters.purpose = purposeController.text.trim();
                                  filters.purposeId =
                                      purposeIdController.text.trim();
                                  filters.company = companyController.text.trim();
                                  filters.companyId =
                                      companyIdController.text.trim();
                                  filters.bank = bankController.text.trim();
                                  filters.bankId = bankIdController.text.trim();
                                  filters.addedBy =
                                      addedByController.text.trim();
                                  filters.categoryId =
                                      categoryIdController.text.trim();
                                  filters.assetTypes =
                                      assetTypesController.text.trim();
                                  filters.minAmount =
                                      minAmountController.text.trim();
                                  filters.maxAmount =
                                      maxAmountController.text.trim();
                                });

                                Navigator.pop(context);
                                fetchExpenses(reset: true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff1f6feb),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                "Apply Filters",
                                style: TextStyle(fontWeight: FontWeight.w600),
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
          },
        );
      },
    );
  }

  int _activeFilterCount() {
    int count = 0;

    final values = [
      filters.search,
      filters.startDate,
      filters.endDate,
      filters.purpose,
      filters.purposeId,
      filters.expenseType,
      filters.company,
      filters.companyId,
      filters.bank,
      filters.bankId,
      filters.addedBy,
      filters.categoryId,
      filters.assetTypes,
      filters.minAmount,
      filters.maxAmount,
    ];

    for (final value in values) {
      if (value.trim().isNotEmpty) count++;
    }

    if (filters.ordering.isNotEmpty && filters.ordering != "-id") {
      count++;
    }

    return count;
  }

  String _formatAmount(dynamic value) {
    final number = _toDouble(value);
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 2,
    );
    return formatter.format(number);
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return "-";
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return date;
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xff1f6feb), width: 1.4),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xff172033),
      ),
    );
  }

  Widget _dateField({
    required String label,
    required String value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value.isEmpty ? label : value,
                style: TextStyle(
                  color: value.isEmpty ? Colors.grey.shade600 : Colors.black87,
                  fontWeight: value.isEmpty ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ),
            if (value.isNotEmpty)
              InkWell(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff172033),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSummaryChip(String type, ExpenseTypeSummary item) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffe4e9f2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xff1f6feb),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _formatAmount(item.amount),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xff172033),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${item.count} entries",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xffeaf2ff),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xffcfe0ff)),
      ),
      child: Text(
        "$label: $value",
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xff1f4ea8),
        ),
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseItem item) {
    final companyName = item.companyName.isEmpty ? "-" : item.companyName;
    final bankName = item.bankName.isEmpty ? "-" : item.bankName;
    final purposeName = item.purposeOfPay.isEmpty ? "-" : item.purposeOfPay;
    final description = item.description.isEmpty ? "-" : item.description;
    final addedBy = item.addedBy.isEmpty ? "-" : item.addedBy;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffe8edf5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xffedf4ff),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xff1f6feb),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "ID #${item.id}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff172033),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffeef6ee),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.expenseType.isEmpty
                                  ? "Unknown"
                                  : item.expenseType,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff2e7d32),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        companyName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatAmount(item.amount),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff172033),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(item.expenseDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xfff8fafc),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _infoRow("Purpose", purposeName),
                  const SizedBox(height: 10),
                  _infoRow("Bank", bankName),
                  const SizedBox(height: 10),
                  _infoRow("Added By", addedBy),
                  const SizedBox(height: 10),
                  _infoRow(
                    "Transaction ID",
                    item.transactionId.isEmpty ? "-" : item.transactionId,
                  ),
                  const SizedBox(height: 10),
                  _infoRow("Description", description),
                  if (item.loanName.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _infoRow("Loan Name", item.loanName),
                  ],
                  if (item.assetTypes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _infoRow("Asset Type", item.assetTypes),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xff172033),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isFirstLoad && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopSearchAndActions(),
                  const SizedBox(height: 16),
                  _buildSummarySection(),
                  const SizedBox(height: 18),
                  _buildActiveFiltersSection(),
                  const SizedBox(height: 18),
                  const Text(
                    "Expense Entries",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff172033),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          expenseList.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 58,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            "No expense data found",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff172033),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Try changing search or filters.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < expenseList.length) {
                          return _buildExpenseCard(expenseList[index]);
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: _isLoadingMore
                                ? const CircularProgressIndicator()
                                : !_hasNextPage
                                ? Text(
                                    "No more data",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      },
                      childCount: expenseList.length + 1,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTopSearchAndActions() {
    final int filterCount = _activeFilterCount();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.045),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: "Search expense, purpose, bank, company...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              filters.search = "";
                              fetchExpenses(reset: true);
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Material(
                  color: const Color(0xff1f6feb),
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _openFilterSheet,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Icon(Icons.tune, color: Colors.white, size: 15),
                    ),
                  ),
                ),
                if (filterCount > 0)
                  Positioned(
                    right: -4,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        filterCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummarySection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: "Total Records",
                value: summary.totalCount.toString(),
                bg: const Color(0xffeef4ff),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: "Total Amount",
                value: _formatAmount(summary.totalAmount),
                bg: const Color(0xffeefbf2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                "Type-wise Summary",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff172033),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: summaryByType.isEmpty
                  ? Center(
                      child: Text(
                        "No summary available",
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      scrollDirection: Axis.horizontal,
                      children: summaryByType.entries
                          .map((e) => _buildTypeSummaryChip(e.key, e.value))
                          .toList(),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveFiltersSection() {
    final chips = <Widget>[
      _buildFilterChip("Search", filters.search),
      _buildFilterChip("From", filters.startDate),
      _buildFilterChip("To", filters.endDate),
      _buildFilterChip("Purpose", filters.purpose),
      _buildFilterChip("Purpose ID", filters.purposeId),
      _buildFilterChip("Type", filters.expenseType),
      _buildFilterChip("Company", filters.company),
      _buildFilterChip("Company ID", filters.companyId),
      _buildFilterChip("Bank", filters.bank),
      _buildFilterChip("Bank ID", filters.bankId),
      _buildFilterChip("Added By", filters.addedBy),
      _buildFilterChip("Category ID", filters.categoryId),
      _buildFilterChip("Asset Type", filters.assetTypes),
      _buildFilterChip("Min", filters.minAmount),
      _buildFilterChip("Max", filters.maxAmount),
      if (filters.ordering.isNotEmpty && filters.ordering != "-id")
        _buildFilterChip("Ordering", filters.ordering),
    ].where((widget) => widget is! SizedBox).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "Applied Filters",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff172033),
                ),
              ),
            ),
            if (_activeFilterCount() > 0)
              TextButton(
                onPressed: _clearAllFilters,
                child: const Text("Clear All"),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (chips.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffe8edf5)),
            ),
            child: Text(
              "No filters applied",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Wrap(
            children: chips,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
         leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () async {
            await _navigateBack();
          },
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff172033),
        title: const Text(
          "Expense List",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xff172033),
          ),
        ),
        centerTitle: false,
      ),
      body: _buildBody(),
    );
  }
}

class DropdownOption {
  final String id;
  final String label;

  const DropdownOption({
    required this.id,
    required this.label,
  });
}

class PurposeOption {
  final int id;
  final String name;

  PurposeOption({
    required this.id,
    required this.name,
  });

  factory PurposeOption.fromJson(Map<String, dynamic> json) {
    return PurposeOption(
      id: json["id"] is int
          ? json["id"]
          : int.tryParse(json["id"].toString()) ?? 0,
      name: json["name"]?.toString() ?? "",
    );
  }
}

class BankOption {
  final int id;
  final String name;

  BankOption({
    required this.id,
    required this.name,
  });

  factory BankOption.fromJson(Map<String, dynamic> json) {
    return BankOption(
      id: json["id"] is int
          ? json["id"]
          : int.tryParse(json["id"].toString()) ?? 0,
      name: json["name"]?.toString() ?? "",
    );
  }
}

class CompanyOption {
  final int id;
  final String name;

  CompanyOption({
    required this.id,
    required this.name,
  });

  factory CompanyOption.fromJson(Map<String, dynamic> json) {
    return CompanyOption(
      id: json["id"] is int
          ? json["id"]
          : int.tryParse(json["id"].toString()) ?? 0,
      name: json["name"]?.toString() ?? "",
    );
  }
}

class StaffOption {
  final int id;
  final String name;

  StaffOption({
    required this.id,
    required this.name,
  });

  factory StaffOption.fromJson(Map<String, dynamic> json) {
    return StaffOption(
      id: json["id"] is int
          ? json["id"]
          : int.tryParse(json["id"].toString()) ?? 0,
      name: json["name"]?.toString() ?? "",
    );
  }
}

class ExpenseFilters {
  String search;
  String startDate;
  String endDate;
  String purpose;
  String purposeId;
  String expenseType;
  String company;
  String companyId;
  String bank;
  String bankId;
  String addedBy;
  String categoryId;
  String assetTypes;
  String minAmount;
  String maxAmount;
  String ordering;

  ExpenseFilters({
    this.search = "",
    this.startDate = "",
    this.endDate = "",
    this.purpose = "",
    this.purposeId = "",
    this.expenseType = "",
    this.company = "",
    this.companyId = "",
    this.bank = "",
    this.bankId = "",
    this.addedBy = "",
    this.categoryId = "",
    this.assetTypes = "",
    this.minAmount = "",
    this.maxAmount = "",
    this.ordering = "-id",
  });
}

class ExpenseSummary {
  final int totalCount;
  final double totalAmount;

  ExpenseSummary({
    required this.totalCount,
    required this.totalAmount,
  });

  factory ExpenseSummary.fromJson(Map<String, dynamic> json) {
    return ExpenseSummary(
      totalCount: _parseInt(json["total_count"]),
      totalAmount: _parseDouble(json["total_amount"]),
    );
  }

  factory ExpenseSummary.empty() {
    return ExpenseSummary(totalCount: 0, totalAmount: 0);
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class ExpenseTypeSummary {
  final int count;
  final double amount;

  ExpenseTypeSummary({
    required this.count,
    required this.amount,
  });

  factory ExpenseTypeSummary.fromJson(Map<String, dynamic> json) {
    return ExpenseTypeSummary(
      count: _parseInt(json["count"]),
      amount: _parseDouble(json["amount"]),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class ExpenseItem {
  final int id;
  final String companyName;
  final String bankName;
  final String purposeOfPay;
  final String amount;
  final String expenseDate;
  final String transactionId;
  final String description;
  final String expenseType;
  final String addedBy;
  final String loanName;
  final String assetTypes;

  ExpenseItem({
    required this.id,
    required this.companyName,
    required this.bankName,
    required this.purposeOfPay,
    required this.amount,
    required this.expenseDate,
    required this.transactionId,
    required this.description,
    required this.expenseType,
    required this.addedBy,
    required this.loanName,
    required this.assetTypes,
  });

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    final companyMap = json["company"] is Map<String, dynamic>
        ? json["company"] as Map<String, dynamic>
        : <String, dynamic>{};

    final bankMap = json["bank"] is Map<String, dynamic>
        ? json["bank"] as Map<String, dynamic>
        : <String, dynamic>{};

    return ExpenseItem(
      id: _parseInt(json["id"]),
      companyName: companyMap["name"]?.toString() ?? "",
      bankName: bankMap["name"]?.toString() ?? "",
      purposeOfPay: json["purpose_of_pay"]?.toString() ?? "",
      amount: json["amount"]?.toString() ?? "0",
      expenseDate: json["expense_date"]?.toString() ?? "",
      transactionId: json["transaction_id"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      expenseType: json["expense_type"]?.toString() ?? "",
      addedBy: json["added_by"]?.toString() ?? "",
      loanName: json["loanname"]?.toString() ?? "",
      assetTypes: json["asset_types"]?.toString() ?? "",
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}