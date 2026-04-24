import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_address.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_credit_note.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_family.dart';
import 'package:beposoft/pages/ACCOUNTS/add_new_customer.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/customer_ledger.dart';
import 'package:beposoft/pages/ACCOUNTS/customer_singleview.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ACCOUNTS/new_product.dart';
import 'package:beposoft/pages/ACCOUNTS/order_request.dart';
import 'package:beposoft/pages/ACCOUNTS/purchases_request.dart';
import 'package:beposoft/pages/ACCOUNTS/recipts_list.dart';
import 'package:beposoft/pages/ACCOUNTS/update_Expense.dart';
import 'package:beposoft/pages/ACCOUNTS/update_staff.dart';
import 'package:beposoft/pages/ACCOUNTS/view_customer.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/HR/hr_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/api.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class staff_list extends StatefulWidget {
  const staff_list({super.key});

  @override
  State<staff_list> createState() => _staff_listState();
}

class _staff_listState extends State<staff_list> {
  drower d = drower();

  final ScrollController _scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  final TextEditingController supervisorIdController = TextEditingController();
  final TextEditingController departmentIdController = TextEditingController();
  final TextEditingController warehouseIdController = TextEditingController();
  final TextEditingController familyController = TextEditingController();

  Timer? _searchDebounce;

  List<Map<String, dynamic>> sta = [];
  List<Map<String, dynamic>> country = [];

  bool isLoading = false;
  bool isPaginationLoading = false;
  bool hasNextPage = false;

  int currentPage = 1;
  int totalCount = 0;
  String? nextPageUrl;
  String? previousPageUrl;

  String selectedApprovalStatus = '';
  String selectedBloodGroup = '';
  String selectedCountryCode = '';
  // 🔽 Dropdown Data Lists
List<Map<String, dynamic>> warehouses = [];
List<Map<String, dynamic>> managers = [];
List<Map<String, dynamic>> departments = [];
List<Map<String, dynamic>> families = [];

// 🔽 Selected Values
String? selectedSupervisorId;
String? selectedDepartmentId;
String? selectedWarehouseId;
String? selectedFamilyId;

  final List<String> approvalStatusOptions = [
    '',
    'approved',
    'pending',
    'disapproved',
  ];

  final List<String> bloodGroupOptions = [
    '',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  List<String> categories = ["cycling", 'skating', 'fitness', 'bepocart'];
  String selectededu = "cycling";

@override
void initState() {
  super.initState();
  getcountry();

  // 🔽 ADD THESE
  getwarehouse();
  getmanegers();
  getdepartments();
  getfamily();

  getstaff(isInitial: true);

  _scrollController.addListener(() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isPaginationLoading &&
        !isLoading &&
        hasNextPage) {
      getstaff(loadMore: true);
    }
  });
}

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    searchController.dispose();
    supervisorIdController.dispose();
    departmentIdController.dispose();
    warehouseIdController.dispose();
    familyController.dispose();
    super.dispose();
  }

  Widget _buildDropdownTile(
      BuildContext context, String title, List<String> options) {
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

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }


  Future<void> getfamily() async {
  final token = await gettokenFromPrefs();
  try {
    final response = await http.get(
      Uri.parse('$api/api/familys/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      List data = parsed['data'];

      setState(() {
        families = data.map((e) => {
              'id': e['id'].toString(),
              'name': e['name'],
            }).toList();
      });
    }
  } catch (e) {}
}

Future<void> getdepartments() async {
  final token = await gettokenFromPrefs();
  try {
    final response = await http.get(
      Uri.parse('$api/api/departments/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      List data = parsed['data'];

      setState(() {
        departments = data.map((e) => {
              'id': e['id'].toString(),
              'name': e['name'],
            }).toList();
      });
    }
  } catch (e) {}
}

Future<void> getmanegers() async {
  final token = await gettokenFromPrefs();
  try {
    final response = await http.get(
      Uri.parse('$api/api/supervisors/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      List data = parsed['data'];

      setState(() {
        managers = data.map((e) => {
              'id': e['id'].toString(),
              'name': e['name'],
            }).toList();
      });
    }
  } catch (e) {}
}

Future<void> getwarehouse() async {
  final token = await gettokenFromPrefs();
  try {
    final response = await http.get(
      Uri.parse('$api/api/warehouse/add/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);

      List<Map<String, dynamic>> temp = [];
      for (var item in parsed) {
        temp.add({
          'id': item['id'].toString(),
          'name': item['name'],
        });
      }

      setState(() {
        warehouses = temp;
      });
    }
  } catch (e) {}
}

  Future<void> getcountry() async {
    final token = await gettokenFromPrefs();
    try {
      final response =
          await http.get(Uri.parse('$api/api/country/codes/'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      List<Map<String, dynamic>> countrylist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          countrylist.add({
            'id': productData['id'],
            'country_code': productData['country_code'].toString(),
          });
        }

        setState(() {
          country = countrylist;
        });
      }
    } catch (e) {}
  }

  Uri _buildStaffUri({int? page}) {
    final queryParams = <String, String>{};

  if (page != null) {
  queryParams['page'] = page.toString();
}

/// 🔍 SEARCH
if (searchController.text.trim().isNotEmpty) {
  queryParams['search'] = searchController.text.trim();
}

/// 🔽 NEW DROPDOWN FILTERS (ADD HERE)
if (selectedSupervisorId != null && selectedSupervisorId!.isNotEmpty) {
  queryParams['supervisor_id'] = selectedSupervisorId!;
}

if (selectedDepartmentId != null && selectedDepartmentId!.isNotEmpty) {
  queryParams['department_id'] = selectedDepartmentId!;
}

if (selectedWarehouseId != null && selectedWarehouseId!.isNotEmpty) {
  queryParams['warehouse_id'] = selectedWarehouseId!;
}

if (selectedFamilyId != null && selectedFamilyId!.isNotEmpty) {
  queryParams['family'] = selectedFamilyId!;
}

/// 🔽 EXISTING FILTERS (KEEP THESE)
if (selectedCountryCode.trim().isNotEmpty) {
  queryParams['country_code'] = selectedCountryCode.trim();
}

if (selectedApprovalStatus.trim().isNotEmpty) {
  queryParams['approval_status'] = selectedApprovalStatus.trim();
}

if (selectedBloodGroup.trim().isNotEmpty) {
  queryParams['blood_group'] = selectedBloodGroup.trim();
}
    return Uri.parse('$api/api/get/staffs/')
        .replace(queryParameters: queryParams);
  }

  Future<void> getstaff({
    bool isInitial = false,
    bool loadMore = false,
  }) async {
    try {
      final token = await gettokenFromPrefs();

      if (!loadMore) {
        setState(() {
          isLoading = true;
          currentPage = 1;
          nextPageUrl = null;
          previousPageUrl = null;
          hasNextPage = false;
          if (isInitial || sta.isNotEmpty) {
            sta = [];
          }
        });
      } else {
        if (!hasNextPage || nextPageUrl == null) return;
        setState(() {
          isPaginationLoading = true;
        });
      }

      Uri requestUri;
      if (loadMore && nextPageUrl != null) {
        requestUri = Uri.parse(nextPageUrl!);
      } else {
        requestUri = _buildStaffUri(page: 1);
      }

      final response = await http.get(
        requestUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        totalCount = parsed['count'] ?? 0;
        nextPageUrl = parsed['next'];
        previousPageUrl = parsed['previous'];
        hasNextPage = nextPageUrl != null;

        final results = parsed['results'];
        final productsData = results != null ? (results['data'] ?? []) : [];

        List<Map<String, dynamic>> stafflist = [];

        for (var productData in productsData) {
          stafflist.add({
            'id': productData['id'],
            'eid': productData['eid'],
            'name': productData['name'],
            'username': productData['username'],
            'email': productData['email'],
            'phone': productData['phone'],
            'designation': productData['designation'],
            'department_name': productData['department_name'],
            'supervisor_name': productData['supervisor_name'],
            'family_name': productData['family_name'],
            'image': productData['image'],
            'approval_status': productData['approval_status'],
            'blood_group': productData['blood_group'],
            'allocated_states_names':
                List<String>.from(productData['allocated_states_names'] ?? []),
            'country_code': productData['country_code'],
            'department_id': productData['department_id'],
            'supervisor_id': productData['supervisor_id'],
            'warehouse_id': productData['warehouse_id'],
            'family': productData['family'],
          });
        }

        setState(() {
          if (loadMore) {
            sta.addAll(stafflist);
            currentPage += 1;
          } else {
            sta = stafflist;
            currentPage = 1;
          }
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch staff list')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isPaginationLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      getstaff();
    });
  }

  Future<void> exportToExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Staff List'];

    sheetObject.appendRow([
      'ID',
      'EID',
      'Name',
      'Email',
      'Phone',
      'Designation',
      'Department',
      'Supervisor',
      'Family',
      'Blood Group',
      'Approval Status',
      'Allocated States'
    ]);

    for (var staff in sta) {
      sheetObject.appendRow([
        staff['id']?.toString() ?? '',
        staff['eid']?.toString() ?? '',
        staff['name']?.toString() ?? '',
        staff['email']?.toString() ?? '',
        staff['phone']?.toString() ?? '',
        staff['designation']?.toString() ?? '',
        staff['department_name']?.toString() ?? '',
        staff['supervisor_name']?.toString() ?? '',
        staff['family_name']?.toString() ?? '',
        staff['blood_group']?.toString() ?? '',
        staff['approval_status']?.toString() ?? '',
        (staff['allocated_states_names'] as List<dynamic>? ?? []).join(', '),
      ]);
    }

    final tempDir = await getTemporaryDirectory();
    final tempPath = "${tempDir.path}/staff_list.xlsx";
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(excel.encode()!);

    await OpenFilex.open(tempPath);
  }

  Future<pw.Document> createPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Text(
                'Staff List',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Total Loaded Staff: ${sta.length}'),
            pw.Text('Total Backend Count: $totalCount'),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: [
                'ID',
                'Name',
                'Email',
                'Designation',
                'Approval',
              ],
              data: [
                for (var staff in sta)
                  [
                    staff['id']?.toString() ?? '',
                    staff['name']?.toString() ?? '',
                    staff['email']?.toString() ?? '',
                    staff['designation']?.toString() ?? '',
                    staff['approval_status']?.toString() ?? '',
                  ]
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 8,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColors.grey400,
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  Future<void> downloadPdf() async {
    final pdf = await createPdf();
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/staff_list.pdf");
    await file.writeAsBytes(await pdf.save());
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'staff_list.pdf',
    );
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('token');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ScaffoldMessenger.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

    await Future.delayed(const Duration(seconds: 2));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login()),
    );
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
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
    } else if (dep == "CEO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ceo_dashboard()),
      );
    } else if (dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ceo_dashboard()),
      );
    } else if (dep == "HR") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HrDashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
  }

  void _clearFilters() {
    setState(() {
      searchController.clear();

      selectedSupervisorId = null;
      selectedDepartmentId = null;
      selectedWarehouseId = null;
      selectedFamilyId = null;

      selectedCountryCode = '';
      selectedApprovalStatus = '';
      selectedBloodGroup = '';
    });
    getstaff();
  }

 void _showFilterBottomSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, modalSetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Filter Staff',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 🔹 SUPERVISOR DROPDOWN
                  DropdownButtonFormField<String>(
                    value: selectedSupervisorId,
                    decoration: const InputDecoration(
                      labelText: 'Supervisor',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text("All"),
                      ),
                      ...managers.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['id'],
                          child: Text(item['name']),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      modalSetState(() => selectedSupervisorId = value);
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 12),

                  /// 🔹 DEPARTMENT DROPDOWN
                  DropdownButtonFormField<String>(
                    value: selectedDepartmentId,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text("All"),
                      ),
                      ...departments.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['id'],
                          child: Text(item['name']),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      modalSetState(() => selectedDepartmentId = value);
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 12),

                  /// 🔹 WAREHOUSE DROPDOWN
                  DropdownButtonFormField<String>(
                    value: selectedWarehouseId,
                    decoration: const InputDecoration(
                      labelText: 'Warehouse',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text("All"),
                      ),
                      ...warehouses.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['id'],
                          child: Text(item['name']),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      modalSetState(() => selectedWarehouseId = value);
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 12),

                  /// 🔹 FAMILY DROPDOWN
                  DropdownButtonFormField<String>(
                    value: selectedFamilyId,
                    decoration: const InputDecoration(
                      labelText: 'Family',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text("All"),
                      ),
                      ...families.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['id'],
                          child: Text(item['name']),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      modalSetState(() => selectedFamilyId = value);
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 12),

                  /// 🔹 APPROVAL STATUS (EXISTING)
                  DropdownButtonFormField<String>(
                    value: selectedApprovalStatus.isEmpty
                        ? null
                        : selectedApprovalStatus,
                    decoration: const InputDecoration(
                      labelText: 'Approval Status',
                      border: OutlineInputBorder(),
                    ),
                    items: approvalStatusOptions.map((value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value.isEmpty ? 'All' : value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      modalSetState(() {
                        selectedApprovalStatus = value ?? '';
                      });
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 12),

                  /// 🔹 BLOOD GROUP (EXISTING)
                  DropdownButtonFormField<String>(
                    value: selectedBloodGroup.isEmpty
                        ? null
                        : selectedBloodGroup,
                    decoration: const InputDecoration(
                      labelText: 'Blood Group',
                      border: OutlineInputBorder(),
                    ),
                    items: bloodGroupOptions.map((value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value.isEmpty ? 'All' : value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      modalSetState(() {
                        selectedBloodGroup = value ?? '';
                      });
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 12),

                  /// 🔹 COUNTRY CODE (EXISTING)
                  DropdownButtonFormField<String>(
                    value: selectedCountryCode.isEmpty
                        ? null
                        : selectedCountryCode,
                    decoration: const InputDecoration(
                      labelText: 'Country Code',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('All'),
                      ),
                      ...country.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['id'].toString(),
                          child: Text(item['country_code'].toString()),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      modalSetState(() {
                        selectedCountryCode = value ?? '';
                      });
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 16),

                  /// 🔹 BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _clearFilters();
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            getstaff();
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
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
  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              "$title :",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _approvalColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'disapproved':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _approvalShortText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'A';
      case 'pending':
        return 'P';
      case 'disapproved':
        return 'D';
      default:
        return 'N';
    }
  }

  Widget _buildPaginationFooter() {
    if (isPaginationLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!hasNextPage && sta.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No more staff',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "Staff List",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final dep = await getdepFromPrefs();
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
              } else if (dep == "CEO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ceo_dashboard()),
                );
              } else if (dep == "COO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ceo_dashboard()),
                );
              } else if (dep == "CSO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => cso_dashboard()),
                );
              } else if (dep == "HR") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HrDashboard()),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => dashboard()),
                );
              }
            },
          ),
          actions: [
            IconButton(
              onPressed: _showFilterBottomSheet,
              icon: const Icon(Icons.filter_list),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'Option 1':
                    exportToExcel();
                    break;
                  case 'Option 2':
                    downloadPdf();
                    break;
                  default:
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'Option 1',
                    child: Text('Export Excel'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Option 2',
                    child: Text('Download Pdf'),
                  ),
                ];
              },
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search Staff...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            searchController.clear();
                            setState(() {});
                            getstaff();
                          },
                          icon: const Icon(Icons.close),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: const BorderSide(
                      color: Colors.blue,
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: const BorderSide(
                      color: Colors.blue,
                      width: 2.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: const BorderSide(
                      color: Colors.blueAccent,
                      width: 2.0,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                  _onSearchChanged(value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Chip(
                  //   label: Text('Loaded: ${sta.length}'),
                  //   backgroundColor: Colors.blue.shade50,
                  // ),
                  // Chip(
                  //   label: Text('Total: $totalCount'),
                  //   backgroundColor: Colors.green.shade50,
                  // ),
                  if (selectedApprovalStatus.isNotEmpty)
                    Chip(
                      label: Text('Status: $selectedApprovalStatus'),
                      onDeleted: () {
                        setState(() {
                          selectedApprovalStatus = '';
                        });
                        getstaff();
                      },
                    ),
                  if (selectedBloodGroup.isNotEmpty)
                    Chip(
                      label: Text('Blood: $selectedBloodGroup'),
                      onDeleted: () {
                        setState(() {
                          selectedBloodGroup = '';
                        });
                        getstaff();
                      },
                    ),
                  if (selectedCountryCode.isNotEmpty)
                    Chip(
                      label: Text('Country ID: $selectedCountryCode'),
                      onDeleted: () {
                        setState(() {
                          selectedCountryCode = '';
                        });
                        getstaff();
                      },
                    ),
                  if (supervisorIdController.text.trim().isNotEmpty)
                    Chip(
                      label: Text('Supervisor: ${supervisorIdController.text}'),
                      onDeleted: () {
                        supervisorIdController.clear();
                        setState(() {});
                        getstaff();
                      },
                    ),
                  if (departmentIdController.text.trim().isNotEmpty)
                    Chip(
                      label: Text('Department: ${departmentIdController.text}'),
                      onDeleted: () {
                        departmentIdController.clear();
                        setState(() {});
                        getstaff();
                      },
                    ),
                  if (warehouseIdController.text.trim().isNotEmpty)
                    Chip(
                      label: Text('Warehouse: ${warehouseIdController.text}'),
                      onDeleted: () {
                        warehouseIdController.clear();
                        setState(() {});
                        getstaff();
                      },
                    ),
                  if (familyController.text.trim().isNotEmpty)
                    Chip(
                      label: Text('Family: ${familyController.text}'),
                      onDeleted: () {
                        familyController.clear();
                        setState(() {});
                        getstaff();
                      },
                    ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : sta.isEmpty
                      ? RefreshIndicator(
                          onRefresh: () async {
                            await getstaff();
                          },
                          child: ListView(
                            children: const [
                              SizedBox(height: 180),
                              Center(
                                child: Text(
                                  'No staff found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await getstaff();
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: sta.length + 1,
                            itemBuilder: (context, index) {
                              if (index == sta.length) {
                                return _buildPaginationFooter();
                              }

                              final staffData = sta[index];
                              final approvalStatus =
                                  (staffData['approval_status'] ?? '')
                                      .toString();

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Staff_Update(
                                        id: staffData['id'],
                                      ),
                                    ),
                                  );
                                },
                                child: Card(
                                  color: Colors.white,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                  elevation: 6,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              child: staffData['image'] !=
                                                          null &&
                                                      staffData['image']
                                                          .toString()
                                                          .isNotEmpty
                                                  ? Image.network(
                                                      "$api${staffData['image']}",
                                                      width: 56,
                                                      height: 56,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Image.asset(
                                                          "lib/assets/user.png",
                                                          width: 56,
                                                          height: 56,
                                                          fit: BoxFit.cover,
                                                        );
                                                      },
                                                    )
                                                  : Image.asset(
                                                      "lib/assets/user.png",
                                                      width: 56,
                                                      height: 56,
                                                      fit: BoxFit.cover,
                                                    ),
                                            ),
                                            Positioned(
                                              bottom: -4,
                                              right: -4,
                                              child: Container(
                                                width: 22,
                                                height: 22,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: _approvalColor(
                                                      approvalStatus),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    _approvalShortText(
                                                        approvalStatus),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                staffData['name']?.toString() ??
                                                    '',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              // _buildInfoRow(
                                              //   'Email',
                                              //   staffData['email']
                                              //           ?.toString() ??
                                              //       '-',
                                              // ),
                                              // _buildInfoRow(
                                              //   'Phone',
                                              //   staffData['phone']
                                              //           ?.toString() ??
                                              //       '-',
                                              // ),
                                              _buildInfoRow(
                                                'Designation',
                                                staffData['designation']
                                                        ?.toString() ??
                                                    '-',
                                              ),
                                              _buildInfoRow(
                                                'Department',
                                                staffData['department_name']
                                                        ?.toString() ??
                                                    '-',
                                              ),
                                              // _buildInfoRow(
                                              //   'Supervisor',
                                              //   staffData['supervisor_name']
                                              //           ?.toString() ??
                                              //       '-',
                                              // ),
                                              _buildInfoRow(
                                                'Family',
                                                staffData['family_name']
                                                        ?.toString() ??
                                                    '-',
                                              ),
                                              // _buildInfoRow(
                                              //   'Blood Group',
                                              //   staffData['blood_group']
                                              //           ?.toString() ??
                                              //       '-',
                                              // ),
                                              // _buildInfoRow(
                                              //   'Status',
                                              //   approvalStatus.isEmpty
                                              //       ? '-'
                                              //       : approvalStatus,
                                              // ),
                                              // _buildInfoRow(
                                              //   'States',
                                              //   (staffData['allocated_states_names']
                                              //                   as List<
                                              //                       dynamic>? ??
                                              //               [])
                                              //           .join(', ')
                                              //           .toString()
                                              //           .isEmpty
                                              //       ? '-'
                                              //       : (staffData[
                                              //                   'allocated_states_names']
                                              //               as List<dynamic>)
                                              //           .join(', '),
                                              // ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
