import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/main.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_credit_note.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_new_customer.dart';
import 'package:beposoft/pages/ACCOUNTS/add_new_stock.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/credit_note_list.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/expense_list.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ACCOUNTS/new_product.dart';
import 'package:beposoft/pages/ACCOUNTS/order_recipts_list.dart';
import 'package:beposoft/pages/ACCOUNTS/order_request.dart';
import 'package:beposoft/pages/ACCOUNTS/purchases_request.dart';
import 'package:beposoft/pages/ACCOUNTS/recipt.report.dart';
import 'package:beposoft/pages/ACCOUNTS/recipts_list.dart';
import 'package:beposoft/pages/ACCOUNTS/update_department.dart';
import 'package:beposoft/pages/ACCOUNTS/update_family.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/api.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class update_recipt extends StatefulWidget {
  final dynamic id;

  const update_recipt({
    super.key,
    required this.id,
  });

  @override
  State<update_recipt> createState() =>
      _update_reciptState();
}

class _update_reciptState extends State<update_recipt> {
  @override
  void initState() {
    super.initState();

    loadDepartment();
    initdata();
    fetchOrderData();
    getbank();
  }

  Future<void> initdata() async {
    await getreciptlist();
  }

  var url = "$api/api/add/department/";

  final TextEditingController transactionid =
      TextEditingController();

  final TextEditingController purposes =
      TextEditingController();

  final TextEditingController amount =
      TextEditingController();

  final TextEditingController createdby =
      TextEditingController();

  final TextEditingController remark =
      TextEditingController();

  final TextEditingController name =
      TextEditingController();

  final TextEditingController uname =
      TextEditingController();

  final TextEditingController textEditingController =
      TextEditingController();

  dynamic respo;
  dynamic departments;

  int? selectedCompanyId;
  int? selectedstaffId;
  int? selectedbankId;

  String selectedstaff = '';
  String? selectedpurpose;
  String? selectedInvoiceId;
  String? selectedValue;

  final List<String> items = [
    'water',
    'electricity',
    'salary',
    'emi',
    'rent',
    'travel',
    'Others',
  ];

  List<Map<String, dynamic>> fam = [];
  List<Map<String, dynamic>> bank = [];
  List<Map<String, dynamic>> orders = [];

  /*
   * Order API pagination variables.
   *
   * These are required because /api/orders/ now returns:
   *
   * {
   *   "count": ...,
   *   "next": ...,
   *   "previous": ...,
   *   "results": {
   *     "results": [...]
   *   }
   * }
   */
  int currentPage = 1;
  int totalPages = 1;
  int pageSize = 50;

  bool hasNextPage = false;
  bool isOrderLoading = false;
  bool isUpdating = false;

  String currentDepartment = '';

  String searchQuery = '';
  String selectedStatus = 'All';

  DateTime? orderStartDate;
  DateTime? orderEndDate;

  Future<String?> gettokenFromPrefs() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('department');
  }

  Future<void> loadDepartment() async {
    final String? department = await getdepFromPrefs();

    if (!mounted) return;

    setState(() {
      currentDepartment =
          department?.trim().toUpperCase() ?? '';
    });
  }

  bool get canUpdate {
    final String department =
        currentDepartment.trim().toUpperCase();

    return department == 'ADMIN' ||
        department == 'COO' ||
        department == 'CEO';
  }

  Future<void> getbank() async {
    final String? token =
        await gettokenFromPrefs();

    try {
      final http.Response response =
          await http.get(
        Uri.parse('$api/api/banks/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final List<Map<String, dynamic>>
          banklist = [];

      if (response.statusCode == 200) {
        final dynamic parsed =
            jsonDecode(response.body);

        final dynamic productsData =
            parsed['data'];

        for (final dynamic productData
            in productsData) {
          banklist.add({
            'id': productData['id'],
            'name': productData['name'],
            'branch': productData['branch'],
          });
        }

        if (!mounted) return;

        setState(() {
          bank = banklist;
        });
      }
    } catch (e) {
      debugPrint(
        'Error fetching banks: $e',
      );
    }
  }

 Future<void> fetchOrderData() async {
  if (isOrderLoading) {
    return;
  }

  if (!mounted) return;

  setState(() {
    isOrderLoading = true;
  });

  try {
    final String? token =
        await gettokenFromPrefs();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Authentication token not found',
      );
    }

    final dynamic jwt = JWT.decode(token);

    final String loggedUserName =
        jwt.payload['name']?.toString() ?? '';

    final Map<String, dynamic> queryParameters = {
      'page': currentPage.toString(),
      'search':
          searchQuery.isNotEmpty ? searchQuery : null,
      'status': selectedStatus != 'All'
          ? selectedStatus
          : null,
      'start_date': orderStartDate != null
          ? DateFormat('yyyy-MM-dd').format(
              orderStartDate!,
            )
          : null,
      'end_date': orderEndDate != null
          ? DateFormat('yyyy-MM-dd').format(
              orderEndDate!,
            )
          : null,
    };

    queryParameters.removeWhere(
      (String key, dynamic value) {
        return value == null ||
            value.toString().isEmpty;
      },
    );

    final Uri uri = Uri.parse(
      '$api/api/orders/',
    ).replace(
      queryParameters: queryParameters.map(
        (String key, dynamic value) {
          return MapEntry(
            key,
            value.toString(),
          );
        },
      ),
    );

    debugPrint('Orders API URL: $uri');

    final http.Response response =
        await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final dynamic decodedResponse =
          jsonDecode(response.body);

      if (decodedResponse
          is! Map<String, dynamic>) {
        throw Exception(
          'Invalid order API response',
        );
      }

      final int totalCount =
          int.tryParse(
                decodedResponse['count']
                        ?.toString() ??
                    '0',
              ) ??
              0;

      totalPages = totalCount == 0
          ? 1
          : (totalCount / pageSize).ceil();

      hasNextPage =
          decodedResponse['next'] != null;

      final dynamic resultsContainer =
          decodedResponse['results'];

      List<dynamic> ordersData = [];

      if (resultsContainer
          is Map<String, dynamic>) {
        final dynamic nestedResults =
            resultsContainer['results'];

        if (nestedResults is List) {
          ordersData = nestedResults;
        }
      } else if (resultsContainer is List) {
        ordersData = resultsContainer;
      }

      final Map<String, Map<String, dynamic>>
          uniqueOrders = {};

      for (final dynamic rawOrderData
          in ordersData) {
        if (rawOrderData is! Map) {
          continue;
        }

        final Map<String, dynamic> orderData =
            Map<String, dynamic>.from(
          rawOrderData,
        );

        final dynamic orderId =
            orderData['id'];

        if (orderId == null) {
          continue;
        }

        String customerName = '';

        final dynamic customerData =
            orderData['customer'];

        if (customerData is Map) {
          customerName =
              customerData['name']?.toString() ??
                  '';
        } else {
          customerName =
              orderData['customer_name']
                      ?.toString() ??
                  customerData?.toString() ??
                  '';
        }

        uniqueOrders[orderId.toString()] = {
          'id': orderId,
          'invoice':
              orderData['invoice']?.toString() ??
                  '',
          'manage_staff':
              orderData['manage_staff'],
          'customer': customerName,
          'warehouse':
              orderData['warehouse_data'],
          'status':
              orderData['status']?.toString() ??
                  '',
          'total_amount':
              orderData['total_amount'],
          'order_date':
              orderData['order_date'],
          'items':
              orderData['items'] ?? [],
          'billing_address':
              orderData['billing_address'] ?? {},
          'bank':
              orderData['bank'] ?? {},
        };
      }

      final List<Map<String, dynamic>>
          newOrders =
          uniqueOrders.values.toList();

      if (!mounted) return;

      setState(() {
        orders = newOrders;
        uname.text = loggedUserName;
      });
    } else {
      debugPrint(
        'Order fetch failed: '
        '${response.statusCode} '
        '${response.body}',
      );
    }
  } catch (error, stackTrace) {
    debugPrint(
      'Error fetching orders: $error',
    );

    debugPrintStack(
      stackTrace: stackTrace,
    );
  } finally {
    if (!mounted) return;

    setState(() {
      isOrderLoading = false;
    });
  }
}

  void getCurrentTime() {
    final DateTime now =
        DateTime.now();

    final String formattedTime =
        DateFormat('HH:mm:ss').format(
      now,
    );

    debugPrint(formattedTime);
  }

  void removeProduct(int index) {
    setState(() {
      fam.removeAt(index);
    });
  }

  DateTime selectedDate =
      DateTime.now();

  Future<void> _selectDate(
    BuildContext context,
  ) async {
    final DateTime? picked =
        await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (!mounted) return;

    if (picked != null &&
        picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String formatDate(DateTime date) {
    return "${date.year}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> getreciptlist() async {
    try {
      final String? token =
          await gettokenFromPrefs();

      final http.Response response =
          await http.get(
        Uri.parse(
          '$api/api/recieptsupdate/get/'
          '${widget.id}/',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic parsed =
            jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          remark.text =
              parsed['remark']?.toString() ??
                  '';

          amount.text =
              parsed['amount']?.toString() ??
                  '';

          transactionid.text =
              parsed['transactionID']
                      ?.toString() ??
                  '';

          selectedDate =
              DateTime.tryParse(
                    parsed['received_at']
                            ?.toString() ??
                        '',
                  ) ??
                  DateTime.now();

          final dynamic rawBankId =
              parsed['bank'];

          selectedbankId =
              rawBankId is int
                  ? rawBankId
                  : int.tryParse(
                      rawBankId
                              ?.toString() ??
                          '',
                    );

          createdby.text =
              parsed['created_by']
                      ?.toString() ??
                  '';

          selectedInvoiceId =
              parsed['order'] != null
                  ? parsed['order']
                      .toString()
                  : null;
        });
      }
    } catch (error) {
      debugPrint(
        'Error fetching receipt: $error',
      );
    }
  }

  Future<void> AddStatusTime(
    BuildContext scaffoldContext,
  ) async {
    final String? token =
        await gettokenFromPrefs();

    try {
      final http.Response response =
          await http.post(
        Uri.parse(
          '$api/api/datalog/create/',
        ),
        headers: {
          'Content-Type':
              'application/json',
          'Authorization':
              'Bearer $token',
        },
        body: jsonEncode({
          'before_data': {
            "Action": "Recipt added ",
          },
          'after_data': {
            "Data": "$respo",
          },
          'order': "",
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          scaffoldContext,
        ).showSnackBar(
          const SnackBar(
            backgroundColor:
                Colors.green,
            content: Text(
              'time added Successfully.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          scaffoldContext,
        ).showSnackBar(
          const SnackBar(
            backgroundColor:
                Colors.red,
            content: Text(
              'Adding time failed.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'Error adding status time: $e',
      );
    }
  }

  Future<void> updateexpense() async {
    if (!canUpdate || isUpdating) {
      return;
    }

    if (!mounted) return;

    setState(() {
      isUpdating = true;
    });

    final String? token =
        await gettokenFromPrefs();

    try {
      final SharedPreferences prefs =
          await SharedPreferences
              .getInstance();

      final String? username =
          prefs.getString('username');

      if (username == null) {
        return;
      }

      if (selectedInvoiceId == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            backgroundColor:
                Colors.red,
            content: Text(
              'Please select an invoice.',
            ),
          ),
        );

        return;
      }

      if (selectedbankId == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            backgroundColor:
                Colors.red,
            content: Text(
              'Please select a bank.',
            ),
          ),
        );

        return;
      }

      final http.Response response =
          await http.put(
        Uri.parse(
          '$api/api/recieptsupdate/get/'
          '${widget.id}/',
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {
          'invoice':
              selectedInvoiceId.toString(),
          'bank':
              selectedbankId.toString(),
          'amount': amount.text,
          'received_at':
              formatDate(selectedDate),
          'transactionID':
              transactionid.text,
          'remark': remark.text,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final dynamic responseData =
            jsonDecode(response.body);

        respo = responseData['data'];

        await AddStatusTime(context);

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (BuildContext context) =>
                    order_recipt_Report(),
          ),
        );

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            backgroundColor:
                Color.fromARGB(
              255,
              49,
              212,
              4,
            ),
            content: Text(
              'Expense Updated successfully',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            backgroundColor:
                Colors.red,
            content: Text(
              'Failed to add expense. '
              'Please try again.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          backgroundColor:
              Colors.red,
          content: Text(
            'An error occurred. '
            'Please try again.',
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isUpdating = false;
      });
    }
  }

  String? get safeSelectedInvoiceId {
    if (selectedInvoiceId == null) {
      return null;
    }

    final bool exists = orders.any(
      (Map<String, dynamic> order) {
        return order['id'].toString() ==
            selectedInvoiceId;
      },
    );

    return exists
        ? selectedInvoiceId
        : null;
  }

  int? get safeSelectedBankId {
    if (selectedbankId == null) {
      return null;
    }

    final bool exists = bank.any(
      (Map<String, dynamic> bankItem) {
        final int? bankId =
            bankItem['id'] is int
                ? bankItem['id'] as int
                : int.tryParse(
                    bankItem['id']
                        .toString(),
                  );

        return bankId ==
            selectedbankId;
      },
    );

    return exists
        ? selectedbankId
        : null;
  }

  @override
  void dispose() {
    transactionid.dispose();
    purposes.dispose();
    amount.dispose();
    createdby.dispose();
    remark.dispose();
    name.dispose();
    uname.dispose();
    textEditingController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color.fromARGB(
        242,
        255,
        255,
        255,
      ),
      appBar: AppBar(
        title: const Text(
          "Update Recipt",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back),
          onPressed: () async {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'lib/assets/profile.png',
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          return SingleChildScrollView(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  Padding(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 1,
                    ),
                    child: Container(
                      width:
                          constraints.maxWidth *
                              0.9,
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius
                                .circular(
                          10,
                        ),
                        border:
                            Border.all(
                          color:
                              const Color
                                  .fromARGB(
                            255,
                            202,
                            202,
                            202,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .all(
                          10,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Container(
                              width:
                                  constraints
                                          .maxWidth *
                                      0.9,
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color
                                        .fromARGB(
                                  255,
                                  2,
                                  65,
                                  96,
                                ),
                                border:
                                    Border.all(
                                  color:
                                      const Color
                                          .fromARGB(
                                    255,
                                    202,
                                    202,
                                    202,
                                  ),
                                ),
                              ),
                              child:
                                  const Column(
                                children: [
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    "Update Recipt",
                                    style:
                                        TextStyle(
                                      fontSize:
                                          20,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      color:
                                          Colors
                                              .white,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 13,
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              "Select Invoice",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                right: 10,
                              ),
                              child: Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal:
                                      10,
                                ),
                                decoration:
                                    BoxDecoration(
                                  border:
                                      Border.all(
                                    color:
                                        Colors
                                            .grey,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    10,
                                  ),
                                ),
                                child:
                                    DropdownButton<
                                        String>(
                                  isExpanded:
                                      true,
                                  value:
                                      safeSelectedInvoiceId,
                                  hint: Text(
                                    isOrderLoading
                                        ? 'Loading invoices...'
                                        : orders
                                                .isEmpty
                                            ? 'No invoices available'
                                            : 'Select Invoice',
                                    style:
                                        const TextStyle(
                                      fontSize:
                                          12,
                                    ),
                                  ),
                                  items:
                                      orders.map(
                                    (
                                      Map<String,
                                              dynamic>
                                          order,
                                    ) {
                                      return DropdownMenuItem<
                                          String>(
                                        value: order[
                                                'id']
                                            .toString(),
                                        child:
                                            Text(
                                          '${order['invoice']}'
                                          ' - '
                                          '${order['customer']}',
                                          overflow:
                                              TextOverflow
                                                  .ellipsis,
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                12,
                                          ),
                                        ),
                                      );
                                    },
                                  ).toList(),
                                  onChanged:
                                      isOrderLoading ||
                                              orders
                                                  .isEmpty
                                          ? null
                                          : (
                                              String?
                                                  value,
                                            ) {
                                              setState(
                                                () {
                                                  selectedInvoiceId =
                                                      value;
                                                },
                                              );
                                            },
                                  underline:
                                      const SizedBox(),
                                ),
                              ),
                            ),
                            const Text(
                              "Amount",
                              style: TextStyle(
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            TextField(
                              controller: amount,
                              decoration:
                                  InputDecoration(
                                labelText:
                                    'Amount',
                                hintText: amount
                                        .text
                                        .isNotEmpty
                                    ? amount.text
                                    : 'Enter your amount',
                                labelStyle:
                                    const TextStyle(
                                  fontSize: 13,
                                ),
                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    10,
                                  ),
                                  borderSide:
                                      const BorderSide(
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                                contentPadding:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical: 8,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            const Text(
                              "Payment Date",
                              style: TextStyle(
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Container(
                              width:
                                  double.infinity,
                              height: 46,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 20,
                              ),
                              decoration:
                                  BoxDecoration(
                                border:
                                    Border.all(
                                  color:
                                      Colors.grey,
                                  width: 1,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${selectedDate.day}/'
                                      '${selectedDate.month}/'
                                      '${selectedDate.year}',
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            15,
                                        color:
                                            Color.fromARGB(
                                          255,
                                          116,
                                          116,
                                          116,
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      _selectDate(
                                        context,
                                      );
                                    },
                                    child:
                                        const Icon(
                                      Icons
                                          .date_range,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            const Text(
                              "Created By",
                              style: TextStyle(
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            TextField(
                              controller:
                                  createdby,
                              readOnly: true,
                              decoration:
                                  InputDecoration(
                                labelStyle:
                                    const TextStyle(
                                  fontSize: 13,
                                ),
                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    10,
                                  ),
                                  borderSide:
                                      const BorderSide(
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                                contentPadding:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical: 8,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            const Text(
                              "Bank",
                              style: TextStyle(
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                right: 10,
                              ),
                              child: Container(
                                height: 49,
                                decoration:
                                    BoxDecoration(
                                  border:
                                      Border.all(
                                    color:
                                        const Color
                                            .fromARGB(
                                      255,
                                      206,
                                      206,
                                      206,
                                    ),
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    10,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Expanded(
                                      child:
                                          InputDecorator(
                                        decoration:
                                            const InputDecoration(
                                          border:
                                              InputBorder
                                                  .none,
                                          hintText:
                                              'Select Bank',
                                          contentPadding:
                                              EdgeInsets
                                                  .symmetric(
                                            horizontal:
                                                1,
                                          ),
                                        ),
                                        child:
                                            DropdownButtonHideUnderline(
                                          child:
                                              DropdownButton<
                                                  int>(
                                            hint:
                                                Text(
                                              'Select Bank',
                                              style:
                                                  TextStyle(
                                                fontSize:
                                                    12,
                                                color:
                                                    Colors.grey[
                                                        600],
                                              ),
                                            ),
                                            value:
                                                safeSelectedBankId,
                                            isExpanded:
                                                true,
                                            dropdownColor:
                                                Colors.white,
                                            icon:
                                                const Icon(
                                              Icons
                                                  .arrow_drop_down,
                                              color:
                                                  Color.fromARGB(
                                                255,
                                                107,
                                                107,
                                                107,
                                              ),
                                            ),
                                            onChanged:
                                                (
                                              int?
                                                  newValue,
                                            ) {
                                              setState(
                                                () {
                                                  selectedbankId =
                                                      newValue;
                                                },
                                              );
                                            },
                                            items:
                                                bank.map<
                                                    DropdownMenuItem<
                                                        int>>(
                                              (
                                                Map<String,
                                                        dynamic>
                                                    bankItem,
                                              ) {
                                                final int?
                                                    bankId =
                                                    bankItem['id']
                                                            is int
                                                        ? bankItem['id']
                                                            as int
                                                        : int.tryParse(
                                                            bankItem['id']
                                                                .toString(),
                                                          );

                                                if (bankId ==
                                                    null) {
                                                  return const DropdownMenuItem<
                                                      int>(
                                                    value:
                                                        null,
                                                    child:
                                                        SizedBox(),
                                                  );
                                                }

                                                return DropdownMenuItem<
                                                    int>(
                                                  value:
                                                      bankId,
                                                  child:
                                                      Text(
                                                    bankItem['name']
                                                            ?.toString() ??
                                                        '',
                                                    style:
                                                        const TextStyle(
                                                      color:
                                                          Colors.black87,
                                                      fontSize:
                                                          12,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Text(
                              "Transaction ID",
                              style: TextStyle(
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            TextField(
                              controller:
                                  transactionid,
                              decoration:
                                  InputDecoration(
                                labelText: 'No.',
                                labelStyle:
                                    const TextStyle(
                                  fontSize: 13,
                                ),
                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    10,
                                  ),
                                  borderSide:
                                      const BorderSide(
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                                contentPadding:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical: 8,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            const Text(
                              "Remark",
                              style: TextStyle(
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            TextField(
                              controller: remark,
                              decoration:
                                  InputDecoration(
                                labelText:
                                    'remark',
                                labelStyle:
                                    const TextStyle(
                                  fontSize: 13,
                                ),
                                border:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    10,
                                  ),
                                  borderSide:
                                      const BorderSide(
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                                contentPadding:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical: 8,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                            ElevatedButton(
                              onPressed:
                                  canUpdate &&
                                          !isUpdating
                                      ? updateexpense
                                      : null,
                              style:
                                  ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty
                                        .resolveWith<
                                            Color>(
                                  (
                                    Set<MaterialState>
                                        states,
                                  ) {
                                    if (states.contains(
                                      MaterialState
                                          .disabled,
                                    )) {
                                      return Colors.grey;
                                    }

                                    return Colors.blue;
                                  },
                                ),
                                shape:
                                    MaterialStateProperty
                                        .all<
                                            RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      10,
                                    ),
                                  ),
                                ),
                                fixedSize:
                                    MaterialStateProperty
                                        .all<Size>(
                                  Size(
                                    constraints
                                            .maxWidth *
                                        0.4,
                                    50,
                                  ),
                                ),
                              ),
                              child:
                                  isUpdating
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<
                                                    Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          "Submit",
                                          style:
                                              TextStyle(
                                            color:
                                                Colors.white,
                                          ),
                                        ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}