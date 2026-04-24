import 'dart:convert';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_family.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/invoice_report.dart';
import 'package:beposoft/pages/ACCOUNTS/update_bank_transfer.dart';
import 'package:beposoft/pages/ACCOUNTS/update_bankrecipt.dart';
import 'package:beposoft/pages/ACCOUNTS/update_recipt.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:intl/intl.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class transfer_list extends StatefulWidget {
  const transfer_list({super.key});

  @override
  State<transfer_list> createState() => transfer_listState();
}

class transfer_listState extends State<transfer_list> {
  List<Map<String, dynamic>> salesReportList = [];
  List<Map<String, dynamic>> allSalesReportList = [];
  List<Map<String, dynamic>> bank = [];
  List<Map<String, dynamic>> customer = [];

  List<Map<String, dynamic>> sta = [];

  double totalstock = 0.0;
  double totalsold = 0.0;
  double remaingitem = 0.0;
  double approvedAmount = 0.0;
  double rejectedBills = 0.0;
  double rejectedAmount = 0.0;
  int totalReceipts = 0;
  double totalAmount = 0.0;

  TextEditingController searchController = TextEditingController();
  TextEditingController staffSearchController = TextEditingController();

  DateTime? selectedDate;
  DateTime? startDate;
  DateTime? endDate;

  bool isLoading = false;
  bool isPaginationLoading = false;
  bool isStaffLoading = false;
  bool isFirstLoad = true;

  int currentPage = 1;
  int totalCount = 0;
  int pageSize = 20;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  String? nextPageUrl;
  String? previousPageUrl;

  int staffCurrentPage = 1;
  int staffTotalCount = 0;
  bool staffHasNextPage = false;
  String? staffNextPageUrl;
  String? staffPreviousPageUrl;

  String selectedSenderBank = '';
  String selectedReceiverBank = '';
  String selectedCreatedBy = '';
  String selectedCreatedByName = '';

  drower d = drower();

  @override
  void initState() {
    super.initState();
    initializePage();
  }

  Future<void> initializePage() async {
    await getbank();
    await getstaff(isInitial: true);
    await getcustomer();
    await getreciptReport(page: 1, showMainLoader: true);
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

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  void _updateTotals() {
    int tempTotalReceipts = 0;
    double tempTotalAmount = 0.0;

    for (var reportData in salesReportList) {
      tempTotalReceipts++;
      tempTotalAmount +=
          double.tryParse(reportData['amount'].toString()) ?? 0.0;
    }

    setState(() {
      totalReceipts = tempTotalReceipts;
      totalAmount = tempTotalAmount;
    });
  }

  Future<void> getbank() async {
    final token = await getTokenFromPrefs();
    try {
      final response = await http.get(
        Uri.parse('$api/api/banks/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      List<Map<String, dynamic>> banklist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          banklist.add({
            'id': productData['id'],
            'name': productData['name'],
            'branch': productData['branch'],
          });
        }

        setState(() {
          bank = banklist;
        });
      }
    } catch (e) {}
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

        List<Map<String, dynamic>> newCustomers = [];

        for (var productData in productsData) {
          newCustomers.add({
            'id': productData['id'],
            'name': productData['name'],
            'created_at': productData['created_at'],
          });
        }

        setState(() {
          customer = newCustomers;
        });
      }
    } catch (error) {}
  }

  Uri _buildStaffUri({int page = 1}) {
    final Map<String, String> params = {
      'page': page.toString(),
    };

    if (staffSearchController.text.trim().isNotEmpty) {
      params['search'] = staffSearchController.text.trim();
    }

    return Uri.parse('$api/api/get/staffs/').replace(queryParameters: params);
  }

  Future<void> getstaff({
    bool isInitial = false,
    bool loadMore = false,
  }) async {
    try {
      final token = await gettokenFromPrefs();

      if (!loadMore) {
        setState(() {
          isStaffLoading = true;
          staffCurrentPage = 1;
          staffNextPageUrl = null;
          staffPreviousPageUrl = null;
          staffHasNextPage = false;
          if (isInitial || sta.isNotEmpty) {
            sta = [];
          }
        });
      } else {
        if (!staffHasNextPage || staffNextPageUrl == null) return;
        setState(() {
          isPaginationLoading = true;
        });
      }

      Uri requestUri;
      if (loadMore && staffNextPageUrl != null) {
        requestUri = Uri.parse(staffNextPageUrl!);
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

        staffTotalCount = parsed['count'] ?? 0;
        staffNextPageUrl = parsed['next'];
        staffPreviousPageUrl = parsed['previous'];
        staffHasNextPage = staffNextPageUrl != null;

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
            staffCurrentPage += 1;
          } else {
            sta = stafflist;
            staffCurrentPage = 1;
          }
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch staff list')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isStaffLoading = false;
          isPaginationLoading = false;
        });
      }
    }
  }

  String formatCreatedAtDate(Map<String, dynamic> reportData) {
    final rawDate = reportData['created_at'];
    if (rawDate == null) return '';

    final parsedDate = DateTime.tryParse(rawDate);
    if (parsedDate == null) return '';

    return DateFormat('yyyy-MM-dd').format(parsedDate);
  }

  Map<String, String> _buildFilterParams({int? page}) {
    final Map<String, String> params = {};

    params['page'] = (page ?? currentPage).toString();

    if (searchController.text.trim().isNotEmpty) {
      params['search'] = searchController.text.trim();
    }

    if (selectedSenderBank.isNotEmpty) {
      params['sender_bank'] = selectedSenderBank;
    }

    if (selectedReceiverBank.isNotEmpty) {
      params['receiver_bank'] = selectedReceiverBank;
    }

    if (selectedCreatedBy.isNotEmpty) {
      params['created_by'] = selectedCreatedBy;
    }

    if (startDate != null) {
      params['start_date'] = DateFormat('yyyy-MM-dd').format(startDate!);
    }

    if (endDate != null) {
      params['end_date'] = DateFormat('yyyy-MM-dd').format(endDate!);
    }

    return params;
  }

  Future<void> getreciptReport({
    int page = 1,
    bool showMainLoader = false,
  }) async {
    if (showMainLoader) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final token = await getTokenFromPrefs();

      final uri = Uri.parse('$api/api/internal/transfers/get/').replace(
        queryParameters: _buildFilterParams(page: page),
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

        final int parsedCount = parsed['count'] ?? 0;
        final dynamic nextValue = parsed['next'];
        final dynamic previousValue = parsed['previous'];
        final List<dynamic> dataList =
            parsed['results'] != null && parsed['results']['data'] != null
                ? parsed['results']['data']
                : [];

        List<Map<String, dynamic>> reciptList = [];

        for (var reportData in dataList) {
          reciptList.add({
            'type': 'Advance Receipt',
            'id': reportData['id'],
            'transactionID': reportData['transactionID'] ?? '',
            'amount': double.tryParse(reportData['amount'].toString()) ?? 0.0,
            'bank': reportData['sender_bank'] ?? '',
            'sender_bank': reportData['sender_bank'] ?? '',
            'receiver_bank': reportData['receiver_bank'] ?? '',
            'receiver_bank_name': reportData['receiver_bank_name'] ?? '',
            'bank_name': reportData['sender_bank_name'] ?? '',
            'date': formatCreatedAtDate(reportData),
            'created_by': reportData['created_by']?.toString() ?? '',
            'created_by_name': reportData['created_by_name'] ?? '',
            'remark': reportData['remark'] ?? reportData['description'] ?? '',
            'payment_receipt': reportData['payment_receipt'] ?? '',
            'created_at': reportData['created_at'],
          });
        }

        print('Fetched ${reciptList.length} transfer records'); 
        print('Total Count from API: $parsedCount');
        print('Next Page URL: $nextValue');
        print('Previous Page URL: $reciptList');


        setState(() {
          currentPage = page;
          totalCount = parsedCount;
          nextPageUrl = nextValue?.toString();
          previousPageUrl = previousValue?.toString();
          hasNextPage = nextValue != null;
          hasPreviousPage = previousValue != null;
          allSalesReportList = reciptList;
          salesReportList = reciptList;
          isFirstLoad = false;
        });

        _updateTotals();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to fetch data')),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error fetching data')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _applyFiltersFromBottomSheet() async {
    Navigator.pop(context);
    await getreciptReport(page: 1, showMainLoader: true);
  }

  Future<void> _clearFiltersFromTop() async {
    setState(() {
      searchController.clear();
      selectedSenderBank = '';
      selectedReceiverBank = '';
      selectedCreatedBy = '';
      selectedCreatedByName = '';
      startDate = null;
      endDate = null;
      currentPage = 1;
    });

    await getreciptReport(page: 1, showMainLoader: true);
  }

  Future<void> _clearFiltersInsideBottomSheet() async {
    setState(() {
      searchController.clear();
      selectedSenderBank = '';
      selectedReceiverBank = '';
      selectedCreatedBy = '';
      selectedCreatedByName = '';
      startDate = null;
      endDate = null;
      currentPage = 1;
    });

    Navigator.pop(context);
    await getreciptReport(page: 1, showMainLoader: true);
  }

  Future<void> _goToNextPage() async {
    if (hasNextPage) {
      await getreciptReport(page: currentPage + 1, showMainLoader: true);
    }
  }

  Future<void> _goToPreviousPage() async {
    if (hasPreviousPage && currentPage > 1) {
      await getreciptReport(page: currentPage - 1, showMainLoader: true);
    }
  }

  Future<void> _pickStartDate(StateSetter setModalState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setModalState(() {
        startDate = picked;
      });
      setState(() {
        startDate = picked;
      });
    }
  }

  Future<void> _pickEndDate(StateSetter setModalState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setModalState(() {
        endDate = picked;
      });
      setState(() {
        endDate = picked;
      });
    }
  }

  bool get hasAnyFilterApplied {
    return searchController.text.trim().isNotEmpty ||
        selectedSenderBank.isNotEmpty ||
        selectedReceiverBank.isNotEmpty ||
        selectedCreatedBy.isNotEmpty ||
        startDate != null ||
        endDate != null;
  }

  Widget _buildRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
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

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
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

  Widget _buildSkeletonBox({
    double height = 16,
    double width = double.infinity,
    EdgeInsets margin = const EdgeInsets.only(bottom: 10),
  }) {
    return Container(
      margin: margin,
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: _SkeletonCardContent(),
      ),
    );
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        String tempSenderBank = selectedSenderBank;
        String tempReceiverBank = selectedReceiverBank;
        String tempCreatedBy = selectedCreatedBy;
        String tempCreatedByName = selectedCreatedByName;
        DateTime? tempStartDate = startDate;
        DateTime? tempEndDate = endDate;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        height: 5,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Filter Transfers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: tempSenderBank.isEmpty ? null : tempSenderBank,
                      decoration: InputDecoration(
                        labelText: 'Sender Bank',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: bank.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['id'].toString(),
                          child: Text(item['name'].toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          tempSenderBank = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value:
                          tempReceiverBank.isEmpty ? null : tempReceiverBank,
                      decoration: InputDecoration(
                        labelText: 'Receiver Bank',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: bank.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['id'].toString(),
                          child: Text(item['name'].toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          tempReceiverBank = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: tempCreatedBy.isEmpty ? null : tempCreatedBy,
                      decoration: InputDecoration(
                        labelText: 'Created By',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: sta.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['id'].toString(),
                          child: Text(item['name'].toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        final staff = sta.firstWhere(
                          (e) => e['id'].toString() == value.toString(),
                          orElse: () => {},
                        );
                        setModalState(() {
                          tempCreatedBy = value ?? '';
                          tempCreatedByName =
                              staff.isNotEmpty ? staff['name'].toString() : '';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (selectedCreatedByName.isNotEmpty ||
                        tempCreatedByName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Selected: ${tempCreatedByName.isNotEmpty ? tempCreatedByName : selectedCreatedByName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: tempStartDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );

                              if (picked != null) {
                                setModalState(() {
                                  tempStartDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade500),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                tempStartDate == null
                                    ? 'Start Date'
                                    : DateFormat('yyyy-MM-dd')
                                        .format(tempStartDate!),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: tempEndDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );

                              if (picked != null) {
                                setModalState(() {
                                  tempEndDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade500),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                tempEndDate == null
                                    ? 'End Date'
                                    : DateFormat('yyyy-MM-dd')
                                        .format(tempEndDate!),
                                style: const TextStyle(fontSize: 14),
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
                          child: ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                selectedSenderBank = tempSenderBank;
                                selectedReceiverBank = tempReceiverBank;
                                selectedCreatedBy = tempCreatedBy;
                                selectedCreatedByName = tempCreatedByName;
                                startDate = tempStartDate;
                                endDate = tempEndDate;
                              });
                              await _applyFiltersFromBottomSheet();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Apply Filter',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await _clearFiltersInsideBottomSheet();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Clear Filter',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopControls() {
    final int startItem =
        salesReportList.isEmpty ? 0 : ((currentPage - 1) * pageSize) + 1;
    final int endItem =
        ((currentPage - 1) * pageSize) + salesReportList.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      hasPreviousPage && !isLoading ? _goToPreviousPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                  ),
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  label: const Text(
                    'Previous',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasNextPage && !isLoading ? _goToNextPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  label: const Text(
                    'Next',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Showing $startItem - $endItem of $totalCount',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hasAnyFilterApplied)
                TextButton.icon(
                  onPressed: _clearFiltersFromTop,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear Filters'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (isLoading && isFirstLoad) {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) => _buildSkeletonCard(),
      );
    }

    if (isLoading && salesReportList.isEmpty) {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) => _buildSkeletonCard(),
      );
    }

    if (salesReportList.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'No transfer data found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => getreciptReport(page: 1, showMainLoader: true),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 260),
            itemCount: salesReportList.length,
            itemBuilder: (context, index) {
              final reportData = salesReportList[index];
              return Card(
                color: Colors.white,
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (reportData['invoice'] != null &&
                          reportData['invoice'].toString().isNotEmpty)
                        _buildRow('Invoice:', reportData['invoice']),
                      if (reportData['customer_name'] != null &&
                          reportData['customer_name'].toString().isNotEmpty)
                        _buildRow('customer:', reportData['customer_name']),
                      _buildRow('Transaction ID:', reportData['transactionID']),
                      _buildRow('Amount:', reportData['amount']),
                      _buildRow('Received At:', reportData['created_at']),
                      _buildRow('Sender Bank:', reportData['bank_name']),
                      _buildRow('Reciver Bank:', reportData['receiver_bank_name']),
                      _buildRow('Created By:', reportData['created_by_name']),
                      _buildRow('Receipt No:', reportData['payment_receipt']),
                      if (reportData['remark'] != null &&
                          reportData['remark'].toString().isNotEmpty)
                        _buildRow('Remark:', reportData['remark']),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  UpdateBankTransferList(id: reportData['id']),
                            ),
                          );
                        },
                        child: const Text(
                          "View",
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Material(
            elevation: 12,
            color: const Color.fromARGB(255, 12, 80, 163),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                color: Color.fromARGB(255, 12, 80, 163),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Page Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Divider(
                    color: Colors.white.withOpacity(0.5),
                    thickness: 1,
                  ),
                  Row(
                    children: [
                      const Text(
                        'Receipts in Page: ',
                        style: TextStyle(color: Colors.white),
                      ),
                      const Spacer(),
                      Text(
                        '$totalReceipts',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Amount in Page: ',
                        style: TextStyle(color: Colors.white),
                      ),
                      const Spacer(),
                      Text(
                        totalAmount.toStringAsFixed(2),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Total Records: ',
                        style: TextStyle(color: Colors.white),
                      ),
                      const Spacer(),
                      Text(
                        '$totalCount',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
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
            "Recipt Report",
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
              } else if (dep == "BDM") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => bdm_dashbord()),
                );
              } else if (dep == "warehouse") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => WarehouseDashboard()),
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
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_alt_outlined),
              onPressed: _openFilterBottomSheet,
            ),
            IconButton(
              icon: Image.asset('lib/assets/profile.png'),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search ...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      await getreciptReport(page: 1, showMainLoader: true);
                    },
                  ),
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
                onSubmitted: (value) async {
                  await getreciptReport(page: 1, showMainLoader: true);
                },
              ),
            ),
            _buildTopControls(),
            Expanded(child: _buildBodyContent()),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCardContent extends StatelessWidget {
  const _SkeletonCardContent();

  Widget _bar({
    double height = 14,
    double width = double.infinity,
    EdgeInsets margin = const EdgeInsets.only(bottom: 10),
  }) {
    return Container(
      height: height,
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: Color(0xffe6e6e6),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bar(width: 160),
        _bar(width: 220),
        _bar(width: 180),
        _bar(width: 190),
        _bar(width: 140),
        _bar(width: 200),
        const SizedBox(height: 10),
        Container(
          height: 38,
          width: 90,
          decoration: BoxDecoration(
            color: const Color(0xffe6e6e6),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}