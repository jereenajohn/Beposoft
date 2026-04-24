import 'dart:convert';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddBdmOrderSelectionPage extends StatefulWidget {
  const AddBdmOrderSelectionPage({super.key});

  @override
  State<AddBdmOrderSelectionPage> createState() =>
      _AddBdmOrderSelectionPageState();
}

class _AddBdmOrderSelectionPageState extends State<AddBdmOrderSelectionPage> {
  bool isSubmitting = false;
  bool isStaffLoading = false;
  bool isInvoiceLoading = false;
  bool isExistingSelectionLoading = false;
  bool isDeletingSelection = false;

  List<Map<String, dynamic>> sta = [];
  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> invoiceList = [];
  List<Map<String, dynamic>> filteredInvoiceList = [];
  List<Map<String, dynamic>> existingSelections = [];

  Set<String> existingOrderInvoices = {};
  Map<int, bool> expandedExistingInvoices = {};

  List<dynamic> allocatedstates = [];
  String family = "";

  int? selectedStaffId;
  String selectedStaffName = "";

  int? selectedInvoiceOrderId;
  String selectedInvoiceNumber = "";
  String selectedInvoiceCustomer = "";
  double selectedInvoiceAmount = 0.0;

  List<Map<String, dynamic>> selectedInvoiceItems = [];

  int existingSelectionCurrentPage = 1;
  int existingSelectionTotalCount = 0;
  String? existingSelectionNextUrl;
  String? existingSelectionPreviousUrl;

  final TextEditingController existingInvoiceSearchCtrl =
      TextEditingController();

  List<Map<String, dynamic>> filteredExistingSelections = [];

  int? loginFamilyId;
  List<Map<String, dynamic>> familyStaffFilterList = [];
  bool isFamilyStaffFilterLoading = false;

  String? selectedExistingStaffId;

  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  @override
  void dispose() {
    existingInvoiceSearchCtrl.dispose();
    super.dispose();
  }

  Future<String?> gettokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> loadInitialData() async {
    await getExistingBdmOrderSelections(page: 1);
    await getprofiledata();
    await getInvoices();
  }

  List<Map<String, dynamic>> _normalizeParsedData(dynamic parsed) {
    if (parsed is List) {
      return List<Map<String, dynamic>>.from(
        parsed.map((e) => Map<String, dynamic>.from(e)),
      );
    }

    if (parsed is Map && parsed['data'] is List) {
      return List<Map<String, dynamic>>.from(
        (parsed['data'] as List).map((e) => Map<String, dynamic>.from(e)),
      );
    }

    if (parsed is Map && parsed['results'] is List) {
      return List<Map<String, dynamic>>.from(
        (parsed['results'] as List).map((e) => Map<String, dynamic>.from(e)),
      );
    }

    return [];
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
    if (!mounted) return;

    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => bdo_dashbord()),
      );
    } else if (dep == "SD") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SdDashboard()),
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

  Future<void> getprofiledata() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse("$api/api/profile/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("PROFILE STATUS: ${response.statusCode}");
      print("PROFILE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        if (!mounted) return;

        setState(() {
          allocatedstates = productsData['allocated_states'] ?? [];
          family = productsData['family_name']?.toString().trim().isNotEmpty ==
                  true
              ? productsData['family_name'].toString().trim()
              : productsData['family_display']?.toString().trim().isNotEmpty ==
                      true
                  ? productsData['family_display'].toString().trim()
                  : productsData['family']?.toString().trim() ?? "";

          loginFamilyId = productsData['family'] is int
              ? productsData['family']
              : int.tryParse(productsData['family']?.toString() ?? "");
        });

        await getstaff();
        await getFamilyStaffsForFilter();
      }
    } catch (error) {
      print("PROFILE ERROR: $error");
    }
  }

  List<String> _extractFamilyCandidates(Map<String, dynamic> productData) {
    final List<String> values = [];

    final possibleKeys = [
      'family_name',
      'family',
      'familyName',
      'family_name_display',
    ];

    for (final key in possibleKeys) {
      final value = productData[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        values.add(value.toString().trim().toLowerCase());
      }
    }

    return values;
  }

  Future<void> getFamilyStaffsForFilter() async {
    try {
      if (loginFamilyId == null) return;

      setState(() {
        isFamilyStaffFilterLoading = true;
      });

      final token = await gettokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/users/family/$loginFamilyId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("FAMILY FILTER STAFF STATUS: ${response.statusCode}");
      print("FAMILY FILTER STAFF BODY: ${response.body}");

      List<Map<String, dynamic>> tempList = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List<dynamic> rawData = parsed['data'] ?? [];

        for (var item in rawData) {
          tempList.add({
            "id": item["id"]?.toString() ?? "",
            "name": item["name"]?.toString() ?? "",
            "staff_id": item["staff_id"]?.toString() ?? "",
          });
        }
      }

      if (!mounted) return;

      setState(() {
        familyStaffFilterList = tempList;
        isFamilyStaffFilterLoading = false;
      });
    } catch (e) {
      print("FAMILY FILTER STAFF ERROR: $e");
      if (!mounted) return;

      setState(() {
        isFamilyStaffFilterLoading = false;
      });
    }
  }

  Future<void> getstaff() async {
    try {
      setState(() {
        isStaffLoading = true;
      });

      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/staffs/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("STAFF STATUS: ${response.statusCode}");
      print("STAFF BODY: ${response.body}");

      List<Map<String, dynamic>> stafflist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        List<Map<String, dynamic>> productsData = _normalizeParsedData(parsed);

        final loginFamily = family.trim().toLowerCase();

        for (var productData in productsData) {
          final familyCandidates = _extractFamilyCandidates(productData);

          final bool matchesFamily = loginFamily.isEmpty
              ? true
              : familyCandidates.contains(loginFamily);

          if (matchesFamily) {
            stafflist.add({
              'id': productData['id'],
              'name': productData['name']?.toString() ?? "",
              'email': productData['email']?.toString() ?? "",
              'designation': productData['designation']?.toString() ?? "",
              'image': productData['image']?.toString() ?? "",
              'approval_status':
                  productData['approval_status']?.toString() ?? "",
              'family_name': productData['family_name']?.toString() ??
                  productData['family']?.toString() ??
                  "",
            });
          }
        }
      }

      if (!mounted) return;

      setState(() {
        sta = stafflist;
        filteredProducts = List.from(sta);
        isStaffLoading = false;
      });

      print("FILTERED STAFF COUNT: ${sta.length}");
      print("LOGIN FAMILY: $family");
    } catch (error) {
      print("STAFF ERROR: $error");
      if (!mounted) return;
      setState(() {
        isStaffLoading = false;
      });
    }
  }

  Future<void> getInvoices() async {
    try {
      setState(() {
        isInvoiceLoading = true;
      });

      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/family/department/orders/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("INVOICE STATUS: ${response.statusCode}");
      print("INVOICE BODY: ${response.body}");

      List<Map<String, dynamic>> tempInvoices = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        List<Map<String, dynamic>> rawData = _normalizeParsedData(parsed);

        for (var item in rawData) {
          tempInvoices.add({
            "id": item["id"],
            "invoice": item["invoice"]?.toString() ?? "",
            "customer": item["customer"]?.toString() ?? "",
            "manage_staff": item["manage_staff"]?.toString() ?? "",
            "staffID": item["staffID"]?.toString() ?? "",
            "family": item["family"]?.toString() ?? "",
            "state": item["state"]?.toString() ?? "",
            "order_date": item["order_date"]?.toString() ?? "",
            "payment_status": item["payment_status"]?.toString() ?? "",
            "status": item["status"]?.toString() ?? "",
            "payment_method": item["payment_method"]?.toString() ?? "",
            "total_amount":
                double.tryParse(item["total_amount"].toString()) ?? 0.0,
          });
        }
      }

      if (!mounted) return;

      setState(() {
        invoiceList = tempInvoices;
        isInvoiceLoading = false;
      });

      if (selectedStaffId != null) {
        _filterInvoicesBySelectedStaff();
      } else {
        setState(() {
          filteredInvoiceList = [];
        });
      }
    } catch (error) {
      print("INVOICE ERROR: $error");
      if (!mounted) return;
      setState(() {
        isInvoiceLoading = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff2196F3),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
      await getExistingBdmOrderSelections(page: 1);
    }
  }

  Future<void> clearSelectedDateRange() async {
    setState(() {
      selectedDateRange = null;
    });
    await getExistingBdmOrderSelections(page: 1);
  }

  Future<void> refreshExistingSelections() async {
    await getExistingBdmOrderSelections(page: existingSelectionCurrentPage);
  }

  String get selectedDateRangeText {
    if (selectedDateRange == null) return "";

    final start = DateFormat("dd MMM yyyy").format(selectedDateRange!.start);
    final end = DateFormat("dd MMM yyyy").format(selectedDateRange!.end);

    return "$start - $end";
  }

  Future<void> getExistingBdmOrderSelections({int page = 1}) async {
    try {
      setState(() {
        isExistingSelectionLoading = true;
      });

      final token = await gettokenFromPrefs();

      final startDate = selectedDateRange == null
          ? null
          : DateFormat('yyyy-MM-dd').format(selectedDateRange!.start);

      final endDate = selectedDateRange == null
          ? null
          : DateFormat('yyyy-MM-dd').format(selectedDateRange!.end);

      final response = await http.get(
        Uri.parse(
          '$api/api/bdm/order/selection/add/?page=$page'
          '${startDate != null ? '&start_date=$startDate' : ''}'
          '${endDate != null ? '&end_date=$endDate' : ''}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("EXISTING SELECTION STATUS: ${response.statusCode}");
      print("EXISTING SELECTION BODY: ${response.body}");

      List<Map<String, dynamic>> tempSelections = [];
      Set<String> tempInvoices = {};

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        existingSelectionTotalCount =
            int.tryParse(parsed["count"].toString()) ?? 0;
        existingSelectionNextUrl = parsed["next"]?.toString();
        existingSelectionPreviousUrl = parsed["previous"]?.toString();
        existingSelectionCurrentPage = page;

        final resultsBlock = parsed["results"];
        final List<dynamic> rawData =
            resultsBlock is Map ? (resultsBlock["data"] ?? []) : [];

        for (var item in rawData) {
          final List<dynamic> items = item["items"] ?? [];

          final normalizedItems = items.map((subItem) {
            return {
              "id": subItem["id"],
              "selection": subItem["selection"],
              "order": subItem["order"],
              "order_id": subItem["order_id"],
              "order_invoice": subItem["order_invoice"]?.toString() ?? "",
              "created_at": subItem["created_at"]?.toString() ?? "",
              "updated_at": subItem["updated_at"]?.toString() ?? "",
            };
          }).toList();

          tempSelections.add({
            "id": item["id"],
            "bdm": item["bdm"],
            "bdm_name": item["bdm_name"]?.toString() ?? "",
            "created_by": item["created_by"],
            "created_by_name": item["created_by_name"]?.toString() ?? "",
            "note": item["note"]?.toString() ?? "",
            "items": normalizedItems,
            "created_at": item["created_at"]?.toString() ?? "",
            "updated_at": item["updated_at"]?.toString() ?? "",
          });

          for (var subItem in items) {
            final invoice =
                subItem["order_invoice"]?.toString().trim().toLowerCase() ?? "";
            if (invoice.isNotEmpty) {
              tempInvoices.add(invoice);
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        existingSelections = tempSelections;
        filteredExistingSelections = List.from(tempSelections);
        existingOrderInvoices = tempInvoices;
        isExistingSelectionLoading = false;
      });

      _applyExistingSelectionFilters();
    } catch (error) {
      print("EXISTING SELECTION ERROR: $error");
      if (!mounted) return;
      setState(() {
        isExistingSelectionLoading = false;
      });
    }
  }

  void _applyExistingSelectionFilters() {
    final invoiceQuery = existingInvoiceSearchCtrl.text.trim().toLowerCase();

    final filtered = existingSelections.where((selection) {
      final bdmId = selection["bdm"]?.toString().trim() ?? "";
      final List<dynamic> items = selection["items"] ?? [];

      final matchesStaff =
          selectedExistingStaffId == null || selectedExistingStaffId == bdmId;

      final matchesInvoice = invoiceQuery.isEmpty ||
          items.any((subItem) {
            final invoice =
                subItem["order_invoice"]?.toString().trim().toLowerCase() ?? "";
            return invoice.contains(invoiceQuery);
          });

      return matchesStaff && matchesInvoice;
    }).toList();

    setState(() {
      filteredExistingSelections = filtered;
    });
  }

  void _filterInvoicesBySelectedStaff() {
    if (selectedStaffId == null) {
      setState(() {
        filteredInvoiceList = [];
      });
      return;
    }

    final staffIdText = selectedStaffId.toString().trim();

    final filtered = invoiceList.where((item) {
      final invoiceStaffId = item["staffID"]?.toString().trim() ?? "";
      return invoiceStaffId == staffIdText;
    }).toList();

    setState(() {
      filteredInvoiceList = filtered;
    });
  }

  String formatDateTime(String value) {
    if (value.trim().isEmpty) return "-";
    try {
      final dt = DateTime.parse(value).toLocal();
      return DateFormat("dd MMM yyyy, hh:mm a").format(dt);
    } catch (e) {
      return value;
    }
  }

  Future<void> showAlreadyAddedInvoicePopup(String invoiceNumber) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Invoice Already Added",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            "Invoice $invoiceNumber is already added before.",
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteExistingSelection(int id) async {
    try {
      setState(() {
        isDeletingSelection = true;
      });

      final token = await gettokenFromPrefs();

      final response = await http.delete(
        Uri.parse('$api/api/bdm/order/selection/edit/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("DELETE SELECTION STATUS: ${response.statusCode}");
      print("DELETE SELECTION BODY: ${response.body}");

      if (!mounted) return;

      setState(() {
        isDeletingSelection = false;
      });

      if (response.statusCode == 200 ||
          response.statusCode == 202 ||
          response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Selection deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );

        int pageToLoad = existingSelectionCurrentPage;

        if (existingSelections.length == 1 &&
            existingSelectionCurrentPage > 1) {
          pageToLoad = existingSelectionCurrentPage - 1;
        }

        await getExistingBdmOrderSelections(page: pageToLoad);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Delete failed: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isDeletingSelection = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> confirmDeleteExistingSelection(int id) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Delete Selection",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          content: const Text(
            "Are you sure you want to delete this order selection?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await deleteExistingSelection(id);
    }
  }

  Future<void> _showStaffBottomSheet() async {
    final TextEditingController searchCtrl = TextEditingController();
    List<Map<String, dynamic>> localFiltered = List.from(sta);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.74,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: SizedBox(
                          width: 42,
                          child: Divider(thickness: 4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Select Staff",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xffF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: searchCtrl,
                          decoration: InputDecoration(
                            hintText: "Search staff...",
                            border: InputBorder.none,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: searchCtrl.text.trim().isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      searchCtrl.clear();
                                      setModalState(() {
                                        localFiltered = List.from(sta);
                                      });
                                    },
                                  )
                                : null,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: (value) {
                            final q = value.trim().toLowerCase();
                            setModalState(() {
                              localFiltered = sta.where((item) {
                                final name =
                                    item["name"]?.toString().toLowerCase() ??
                                        "";
                                final email =
                                    item["email"]?.toString().toLowerCase() ??
                                        "";
                                final designation = item["designation"]
                                        ?.toString()
                                        .toLowerCase() ??
                                    "";
                                return name.contains(q) ||
                                    email.contains(q) ||
                                    designation.contains(q);
                              }).toList();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: localFiltered.isEmpty
                            ? const Center(
                                child: Text(
                                  "No staff found",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: localFiltered.length,
                                separatorBuilder: (_, __) =>
                                    Divider(color: Colors.grey.shade200),
                                itemBuilder: (context, index) {
                                  final item = localFiltered[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      item["name"]?.toString() ?? "",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      item["designation"]
                                                  ?.toString()
                                                  .isNotEmpty ==
                                              true
                                          ? item["designation"].toString()
                                          : item["email"]?.toString() ?? "",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        selectedStaffId = item["id"] is int
                                            ? item["id"]
                                            : int.tryParse(
                                                item["id"].toString(),
                                              );
                                        selectedStaffName =
                                            item["name"]?.toString() ?? "";
                                        selectedInvoiceOrderId = null;
                                        selectedInvoiceNumber = "";
                                        selectedInvoiceCustomer = "";
                                        selectedInvoiceAmount = 0.0;
                                        selectedInvoiceItems = [];
                                      });
                                      _filterInvoicesBySelectedStaff();
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
  }

  Future<void> _showInvoiceBottomSheet() async {
    final TextEditingController searchCtrl = TextEditingController();
    List<Map<String, dynamic>> localFiltered = List.from(filteredInvoiceList);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.78,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: SizedBox(
                          width: 42,
                          child: Divider(thickness: 4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Select Invoice",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xffF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: searchCtrl,
                          decoration: InputDecoration(
                            hintText: "Search invoice / customer / state...",
                            border: InputBorder.none,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: searchCtrl.text.trim().isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      searchCtrl.clear();
                                      setModalState(() {
                                        localFiltered =
                                            List.from(filteredInvoiceList);
                                      });
                                    },
                                  )
                                : null,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: (value) {
                            final q = value.trim().toLowerCase();
                            setModalState(() {
                              localFiltered = filteredInvoiceList.where((item) {
                                final invoice =
                                    item["invoice"]?.toString().toLowerCase() ??
                                        "";
                                final customer = item["customer"]
                                        ?.toString()
                                        .toLowerCase() ??
                                    "";
                                final state =
                                    item["state"]?.toString().toLowerCase() ??
                                        "";
                                return invoice.contains(q) ||
                                    customer.contains(q) ||
                                    state.contains(q);
                              }).toList();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: localFiltered.isEmpty
                            ? const Center(
                                child: Text(
                                  "No invoices found for selected staff",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: localFiltered.length,
                                separatorBuilder: (_, __) =>
                                    Divider(color: Colors.grey.shade200),
                                itemBuilder: (context, index) {
                                  final item = localFiltered[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      item["invoice"]?.toString() ?? "",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          "Customer: ${item["customer"] ?? "-"}",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          "State: ${item["state"] ?? "-"}",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "₹${(item["total_amount"] ?? 0).toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xff0F9D58),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item["order_date"]?.toString() ?? "",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        selectedInvoiceOrderId =
                                            item["id"] is int
                                                ? item["id"]
                                                : int.tryParse(
                                                    item["id"].toString(),
                                                  );
                                        selectedInvoiceNumber =
                                            item["invoice"]?.toString() ?? "";
                                        selectedInvoiceCustomer =
                                            item["customer"]?.toString() ?? "";
                                        selectedInvoiceAmount =
                                            (item["total_amount"] ?? 0)
                                                .toDouble();
                                      });
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
  }

  void addSelectedInvoice() {
    if (selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select staff first"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedInvoiceOrderId == null || selectedInvoiceNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an invoice"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedInvoiceText = selectedInvoiceNumber.trim().toLowerCase();
    final alreadyExistsInApi =
        existingOrderInvoices.contains(selectedInvoiceText);

    if (alreadyExistsInApi) {
      showAlreadyAddedInvoicePopup(selectedInvoiceNumber);
      return;
    }

    final existsInCurrentList = selectedInvoiceItems.any(
      (item) =>
          (item["invoice_number"]?.toString().trim().toLowerCase() ?? "") ==
          selectedInvoiceText,
    );

    if (existsInCurrentList) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This invoice is already added"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      selectedInvoiceItems.add({
        "order": selectedInvoiceOrderId,
        "invoice_number": selectedInvoiceNumber,
        "customer": selectedInvoiceCustomer,
        "total_amount": selectedInvoiceAmount,
      });

      selectedInvoiceOrderId = null;
      selectedInvoiceNumber = "";
      selectedInvoiceCustomer = "";
      selectedInvoiceAmount = 0.0;
    });
  }

  void removeSelectedInvoice(int index) {
    setState(() {
      selectedInvoiceItems.removeAt(index);
    });
  }

  Future<void> submitSelection() async {
    if (selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select staff"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedInvoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add at least one invoice"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        isSubmitting = true;
      });

      final token = await gettokenFromPrefs();

      final payload = {
        "bdm": selectedStaffId,
        "note": "",
        "items": selectedInvoiceItems
            .map((e) => {
                  "order": e["order"],
                  "invoice_number": e["invoice_number"],
                })
            .toList(),
      };

      final response = await http.post(
        Uri.parse('$api/api/bdm/order/selection/add/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      print("POST STATUS: ${response.statusCode}");
      print("POST BODY: ${response.body}");

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order selection added successfully"),
            backgroundColor: Colors.green,
          ),
        );

        await getExistingBdmOrderSelections(page: 1);

        setState(() {
          selectedStaffId = null;
          selectedStaffName = "";
          selectedInvoiceOrderId = null;
          selectedInvoiceNumber = "";
          selectedInvoiceCustomer = "";
          selectedInvoiceAmount = 0.0;
          selectedInvoiceItems = [];
          filteredInvoiceList = [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildExistingSelectionSearchFilterBox() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xffF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: existingInvoiceSearchCtrl,
            decoration: InputDecoration(
              hintText: "Search Invoice",
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: existingInvoiceSearchCtrl.text.trim().isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          existingInvoiceSearchCtrl.clear();
                        });
                        _applyExistingSelectionFilters();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            onChanged: (value) {
              setState(() {});
              _applyExistingSelectionFilters();
            },
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xffF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownSearch<Map<String, dynamic>>(
            items: familyStaffFilterList,
            itemAsString: (item) => item["name"]?.toString() ?? "",
            selectedItem: familyStaffFilterList.any(
              (e) => e["id"]?.toString() == selectedExistingStaffId,
            )
                ? familyStaffFilterList.firstWhere(
                    (e) => e["id"]?.toString() == selectedExistingStaffId,
                  )
                : null,
            compareFn: (a, b) => a["id"]?.toString() == b["id"]?.toString(),
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: "Search staff...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              itemBuilder: (context, item, isSelected) {
                return ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(item["name"]?.toString() ?? ""),
                );
              },
            ),
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                hintText: isFamilyStaffFilterLoading
                    ? "Loading staff..."
                    : "Filter by staff",
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.filter_list),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
            clearButtonProps: ClearButtonProps(
              isVisible: selectedExistingStaffId != null,
              onPressed: () {
                setState(() {
                  selectedExistingStaffId = null;
                });
                _applyExistingSelectionFilters();
              },
            ),
            dropdownButtonProps: const DropdownButtonProps(
              icon: Icon(Icons.arrow_drop_down),
            ),
            onChanged: (value) {
              setState(() {
                selectedExistingStaffId = value?["id"]?.toString();
              });
              _applyExistingSelectionFilters();
            },
          ),
        ),
      ],
    );
  }

  Widget buildSectionCard({
    required String title,
    required Widget child,
    IconData? icon,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: const Color(0xff2196F3)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1E293B),
                      ),
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSelectionField({
    required String label,
    required String hintText,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onClear,
    bool isLoadingField = false,
  }) {
    final bool hasValue = value.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xffF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xff2196F3), size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasValue ? value : hintText,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasValue ? Colors.black87 : Colors.grey.shade500,
                      fontWeight:
                          hasValue ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isLoadingField)
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (hasValue)
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(Icons.close, size: 18),
                  )
                else
                  const Icon(Icons.arrow_drop_down, size: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildInvoicePreviewBox() {
    if (selectedInvoiceOrderId == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffEFF8FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xff2196F3).withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: Color(0xff2196F3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedInvoiceNumber,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  selectedInvoiceCustomer,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "₹${selectedInvoiceAmount.toStringAsFixed(0)}",
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xff0F9D58),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSelectedInvoiceList() {
    if (selectedInvoiceItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xffF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: Colors.grey.shade400,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              "No invoices added yet",
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(selectedInvoiceItems.length, (index) {
        final item = selectedInvoiceItems[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: const Color(0xff2196F3).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Color(0xff2196F3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item["invoice_number"]?.toString() ?? "",
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item["customer"]?.toString() ?? "",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${(item["total_amount"] ?? 0).toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff0F9D58),
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => removeSelectedInvoice(index),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 13,
                            color: Colors.red,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Remove",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget buildExistingSelectionCard(Map<String, dynamic> item) {
    final List<dynamic> items = item["items"] ?? [];
    final String bdmName = item["bdm_name"]?.toString() ?? "-";
    final String createdBy = item["created_by_name"]?.toString() ?? "-";
    final int id = item["id"];

    final bool isExpanded = expandedExistingInvoices[id] ?? false;
    final List<dynamic> visibleItems =
        isExpanded ? items : items.take(2).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xff2196F3).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_outlined,
                      color: Color(0xff2196F3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bdmName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Created by $createdBy",
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: isDeletingSelection
                        ? null
                        : () async {
                            await confirmDeleteExistingSelection(id);
                          },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                "Invoices",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff334155),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: visibleItems.map<Widget>((subItem) {
                  final invoice =
                      subItem["order_invoice"]?.toString().trim().isNotEmpty ==
                              true
                          ? subItem["order_invoice"].toString()
                          : "-";
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xffBFDBFE),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 15,
                          color: Color(0xff2563EB),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          invoice,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff1D4ED8),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              if (items.length > 2) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        expandedExistingInvoices[id] = !isExpanded;
                      });
                    },
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: const Color(0xff2196F3),
                    ),
                    label: Text(
                      isExpanded ? "See less" : "See more",
                      style: const TextStyle(
                        color: Color(0xff2196F3),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget buildExistingSelectionPagination() {
    if (existingSelectionTotalCount == 0) {
      return const SizedBox.shrink();
    }

    final int startItem = existingSelections.isEmpty
        ? 0
        : ((existingSelectionCurrentPage - 1) * existingSelections.length) + 1;
    final int endItem = existingSelections.isEmpty
        ? 0
        : startItem + existingSelections.length - 1;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            "Showing $startItem - $endItem of $existingSelectionTotalCount",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (existingSelectionPreviousUrl == null ||
                          isExistingSelectionLoading)
                      ? null
                      : () async {
                          await getExistingBdmOrderSelections(
                            page: existingSelectionCurrentPage - 1,
                          );
                        },
                  icon: const Icon(Icons.chevron_left),
                  label: const Text("Previous"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (existingSelectionNextUrl == null ||
                          isExistingSelectionLoading)
                      ? null
                      : () async {
                          await getExistingBdmOrderSelections(
                            page: existingSelectionCurrentPage + 1,
                          );
                        },
                  icon: const Icon(Icons.chevron_right),
                  label: const Text("Next"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2196F3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildMetaBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xff64748B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildExistingSelectionsSection() {
    if (isExistingSelectionLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (filteredExistingSelections.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xffF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 34,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 10),
            Text(
              "No order selections found",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ...filteredExistingSelections
            .map((item) => buildExistingSelectionCard(item))
            .toList(),
        buildExistingSelectionPagination(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () async {
            await _navigateBack();
          },
        ),
        titleSpacing: 8,
        title: Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "BDM Invoice Selection",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (selectedDateRange != null) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedDateRangeText,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: isExistingSelectionLoading
                          ? null
                          : clearSelectedDateRange,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: isExistingSelectionLoading ? null : _pickDateRange,
            icon: const Icon(
              Icons.calendar_today_outlined,
              color: Colors.black87,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: isExistingSelectionLoading ? null : refreshExistingSelections,
            icon: isExistingSelectionLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.refresh,
                    color: Colors.black87,
                  ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          const SizedBox(height: 14),
          buildSectionCard(
            title: "Staff Selection",
            icon: Icons.person_outline,
            child: Column(
              children: [
                buildSelectionField(
                  label: "Select Staff",
                  hintText: isStaffLoading
                      ? "Loading staff..."
                      : "Choose BDO / staff",
                  value: selectedStaffName,
                  icon: Icons.badge_outlined,
                  isLoadingField: isStaffLoading,
                  onTap: () async {
                    if (isStaffLoading) return;
                    await _showStaffBottomSheet();
                  },
                  onClear: () {
                    setState(() {
                      selectedStaffId = null;
                      selectedStaffName = "";
                      selectedInvoiceOrderId = null;
                      selectedInvoiceNumber = "";
                      selectedInvoiceCustomer = "";
                      selectedInvoiceAmount = 0.0;
                      selectedInvoiceItems = [];
                      filteredInvoiceList = [];
                    });
                  },
                ),
              ],
            ),
          ),
          buildSectionCard(
            title: "Invoice Selection",
            icon: Icons.receipt_long_outlined,
            child: Column(
              children: [
                buildSelectionField(
                  label: "Select Invoice",
                  hintText: selectedStaffId == null
                      ? "Select staff first"
                      : isInvoiceLoading
                          ? "Loading invoices..."
                          : "Choose invoice",
                  value: selectedInvoiceNumber,
                  icon: Icons.inventory_2_outlined,
                  isLoadingField: isInvoiceLoading,
                  onTap: () async {
                    if (selectedStaffId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please select staff first"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (isInvoiceLoading) return;
                    await _showInvoiceBottomSheet();
                  },
                  onClear: () {
                    setState(() {
                      selectedInvoiceOrderId = null;
                      selectedInvoiceNumber = "";
                      selectedInvoiceCustomer = "";
                      selectedInvoiceAmount = 0.0;
                    });
                  },
                ),
                buildInvoicePreviewBox(),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: addSelectedInvoice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2196F3),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      "Add Invoice",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          buildSectionCard(
            title: "Selected Invoices",
            icon: Icons.list_alt_outlined,
            child: buildSelectedInvoiceList(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : submitSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0F9D58),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Submit Selection",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          buildExistingSelectionSearchFilterBox(),
          const SizedBox(height: 16),
          buildSectionCard(
            title: "Existing Order Selections",
            icon: Icons.history_outlined,
            trailing: InkWell(
              onTap: isExistingSelectionLoading
                  ? null
                  : () async {
                      await getExistingBdmOrderSelections(
                        page: existingSelectionCurrentPage,
                      );
                    },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xff2196F3).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 15,
                      color: Color(0xff2196F3),
                    ),
                    SizedBox(width: 5),
                    Text(
                      "Refresh",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2196F3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            child: buildExistingSelectionsSection(),
          ),
        ],
      ),
    );
  }
}