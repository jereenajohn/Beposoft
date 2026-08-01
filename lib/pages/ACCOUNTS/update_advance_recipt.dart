import 'dart:convert';

import 'package:beposoft/pages/ACCOUNTS/advance_receipt_list.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class update_advance_recipt extends StatefulWidget {
  final dynamic id;

  const update_advance_recipt({
    super.key,
    required this.id,
  });

  @override
  State<update_advance_recipt> createState() =>
      _update_advance_reciptState();
}

class _update_advance_reciptState extends State<update_advance_recipt> {
  final TextEditingController transactionid = TextEditingController();
  final TextEditingController amount = TextEditingController();
  final TextEditingController createdby = TextEditingController();
  final TextEditingController remark = TextEditingController();

  List<Map<String, dynamic>> customer = [];
  List<Map<String, dynamic>> bank = [];

  String? selectedCustomerId;
  int? selectedbankId;

  String currentDepartment = '';

  DateTime selectedDate = DateTime.now();

  bool isLoading = true;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    initializePage();
  }

  Future<void> initializePage() async {
    try {
      final String? department = await getdepFromPrefs();

      if (!mounted) return;

      setState(() {
        currentDepartment =
            department?.trim().toUpperCase() ?? '';
      });

      // Load dropdown data first.
      await getcustomer();

      if (!mounted) return;

      await getbank();

      if (!mounted) return;

      // Load saved receipt values after dropdown items are available.
      await getreciptlist();
    } catch (error, stackTrace) {
      debugPrint('Page initialization error: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String?> getTokenFromPrefs() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('department');
  }

  bool get canUpdate {
    final String department =
        currentDepartment.trim().toUpperCase();

    return department == 'ADMIN' ||
        department == 'COO' ||
        department == 'CEO';
  }

  int? parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  List<Map<String, dynamic>> get uniqueCustomerList {
    final Map<String, Map<String, dynamic>> uniqueMap = {};

    for (final Map<String, dynamic> customerItem in customer) {
      final dynamic customerId = customerItem['id'];

      if (customerId == null) {
        continue;
      }

      uniqueMap[customerId.toString()] = customerItem;
    }

    final List<Map<String, dynamic>> customerList =
        uniqueMap.values.toList();

    customerList.sort(
      (
        Map<String, dynamic> first,
        Map<String, dynamic> second,
      ) {
        final String firstName =
            first['name']?.toString().toLowerCase() ?? '';

        final String secondName =
            second['name']?.toString().toLowerCase() ?? '';

        return firstName.compareTo(secondName);
      },
    );

    return customerList;
  }

  List<Map<String, dynamic>> get uniqueBankList {
    final Map<int, Map<String, dynamic>> uniqueMap = {};

    for (final Map<String, dynamic> bankItem in bank) {
      final int? bankId = parseInt(bankItem['id']);

      if (bankId == null) {
        continue;
      }

      uniqueMap[bankId] = bankItem;
    }

    return uniqueMap.values.toList();
  }

  String? get safeSelectedCustomerId {
    if (selectedCustomerId == null ||
        selectedCustomerId!.trim().isEmpty) {
      return null;
    }

    final bool exists = uniqueCustomerList.any(
      (Map<String, dynamic> customerItem) {
        return customerItem['id'].toString() ==
            selectedCustomerId;
      },
    );

    return exists ? selectedCustomerId : null;
  }

  int? get safeSelectedBankId {
    if (selectedbankId == null) {
      return null;
    }

    final bool exists = uniqueBankList.any(
      (Map<String, dynamic> bankItem) {
        return parseInt(bankItem['id']) == selectedbankId;
      },
    );

    return exists ? selectedbankId : null;
  }

  List<dynamic> extractCustomerList(dynamic parsed) {
    if (parsed is List) {
      return parsed;
    }

    if (parsed is Map<String, dynamic>) {
      if (parsed['data'] is List) {
        return parsed['data'] as List<dynamic>;
      }

      if (parsed['results'] is List) {
        return parsed['results'] as List<dynamic>;
      }

      if (parsed['customers'] is List) {
        return parsed['customers'] as List<dynamic>;
      }

      if (parsed['data'] is Map<String, dynamic>) {
        final Map<String, dynamic> nestedData =
            parsed['data'] as Map<String, dynamic>;

        if (nestedData['results'] is List) {
          return nestedData['results'] as List<dynamic>;
        }

        if (nestedData['data'] is List) {
          return nestedData['data'] as List<dynamic>;
        }

        if (nestedData['customers'] is List) {
          return nestedData['customers'] as List<dynamic>;
        }
      }
    }

    return [];
  }

  Future<void> getcustomer() async {
    try {
      final String? token = await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        debugPrint('Customer API: token not found');
        return;
      }

      final http.Response response = await http.get(
        Uri.parse('$api/api/customers/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
        'Customer API status: ${response.statusCode}',
      );
      debugPrint(
        'Customer API response: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load customers. '
          'Status: ${response.statusCode}',
        );
      }

      final dynamic parsed = jsonDecode(response.body);

      final List<dynamic> customersData =
          extractCustomerList(parsed);

      final Map<String, Map<String, dynamic>> uniqueCustomers =
          {};

      for (final dynamic item in customersData) {
        if (item is! Map) {
          continue;
        }

        final Map<String, dynamic> customerData =
            Map<String, dynamic>.from(item);

        final dynamic rawCustomerId = customerData['id'];

        if (rawCustomerId == null) {
          continue;
        }

        final String customerId =
            rawCustomerId.toString();

        final String customerName =
            customerData['name']?.toString().trim() ??
            customerData['customer_name']
                ?.toString()
                .trim() ??
            customerData['company_name']
                ?.toString()
                .trim() ??
            'Customer $customerId';

        uniqueCustomers[customerId] = {
          'id': rawCustomerId,
          'name': customerName.isEmpty
              ? 'Customer $customerId'
              : customerName,
          'created_at': customerData['created_at'],
        };
      }

      debugPrint(
        'Customer dropdown count: '
        '${uniqueCustomers.length}',
      );

      if (!mounted) return;

      setState(() {
        customer = uniqueCustomers.values.toList();
      });
    } catch (error, stackTrace) {
      debugPrint('Customer API error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        customer = [];
      });
    }
  }

  List<dynamic> extractBankList(dynamic parsed) {
    if (parsed is List) {
      return parsed;
    }

    if (parsed is Map<String, dynamic>) {
      if (parsed['data'] is List) {
        return parsed['data'] as List<dynamic>;
      }

      if (parsed['results'] is List) {
        return parsed['results'] as List<dynamic>;
      }

      if (parsed['banks'] is List) {
        return parsed['banks'] as List<dynamic>;
      }

      if (parsed['data'] is Map<String, dynamic>) {
        final Map<String, dynamic> nestedData =
            parsed['data'] as Map<String, dynamic>;

        if (nestedData['results'] is List) {
          return nestedData['results'] as List<dynamic>;
        }

        if (nestedData['data'] is List) {
          return nestedData['data'] as List<dynamic>;
        }
      }
    }

    return [];
  }

  Future<void> getbank() async {
    try {
      final String? token = await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        debugPrint('Bank API: token not found');
        return;
      }

      final http.Response response = await http.get(
        Uri.parse('$api/api/banks/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Bank API status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load banks. '
          'Status: ${response.statusCode}',
        );
      }

      final dynamic parsed = jsonDecode(response.body);

      final List<dynamic> banksData =
          extractBankList(parsed);

      final Map<int, Map<String, dynamic>> uniqueBanks = {};

      for (final dynamic item in banksData) {
        if (item is! Map) {
          continue;
        }

        final Map<String, dynamic> bankData =
            Map<String, dynamic>.from(item);

        final int? bankId = parseInt(bankData['id']);

        if (bankId == null) {
          continue;
        }

        uniqueBanks[bankId] = {
          'id': bankId,
          'name': bankData['name']?.toString() ??
              'Unknown Bank',
          'branch':
              bankData['branch']?.toString() ?? '',
        };
      }

      if (!mounted) return;

      setState(() {
        bank = uniqueBanks.values.toList();
      });
    } catch (error, stackTrace) {
      debugPrint('Bank API error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        bank = [];
      });
    }
  }

  Future<void> getreciptlist() async {
    try {
      final String? token = await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        debugPrint('Receipt API: token not found');
        return;
      }

      final http.Response response = await http.get(
        Uri.parse(
          '$api/api/advancereceipt/view/${widget.id}/',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
        'Receipt API status: ${response.statusCode}',
      );
      debugPrint(
        'Receipt API response: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load advance receipt. '
          'Status: ${response.statusCode}',
        );
      }

      final dynamic parsed = jsonDecode(response.body);

      if (parsed is! Map<String, dynamic>) {
        throw Exception(
          'Invalid advance receipt response format',
        );
      }

      final String? receivedAt =
          parsed['received_at']?.toString();

      final DateTime parsedDate =
          receivedAt != null && receivedAt.isNotEmpty
              ? DateTime.tryParse(receivedAt) ??
                  DateTime.now()
              : DateTime.now();

      final dynamic rawCustomer = parsed['customer'];

      String? receiptCustomerId;

      if (rawCustomer is Map) {
        receiptCustomerId =
            rawCustomer['id']?.toString();
      } else if (rawCustomer != null) {
        receiptCustomerId = rawCustomer.toString();
      }

      final dynamic rawBank = parsed['bank'];

      int? receiptBankId;

      if (rawBank is Map) {
        receiptBankId = parseInt(rawBank['id']);
      } else {
        receiptBankId = parseInt(rawBank);
      }

      if (!mounted) return;

      setState(() {
        remark.text =
            parsed['remark']?.toString() ?? '';

        amount.text =
            parsed['amount']?.toString() ?? '';

        transactionid.text =
            parsed['transactionID']?.toString() ??
            parsed['transaction_id']?.toString() ??
            '';

        createdby.text =
            parsed['created_by_name']?.toString() ??
            parsed['created_by']?.toString() ??
            '';

        selectedDate = parsedDate;
        selectedCustomerId = receiptCustomerId;
        selectedbankId = receiptBankId;
      });
    } catch (error, stackTrace) {
      debugPrint('Receipt API error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> selectDate(
    BuildContext context,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (!mounted) return;

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  void showSnackBar({
    required String message,
    required Color backgroundColor,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: backgroundColor,
          content: Text(message),
        ),
      );
  }

  Future<void> updateexpense() async {
    if (!canUpdate || isUpdating) {
      return;
    }

    final String? customerId =
        safeSelectedCustomerId;

    final int? bankId =
        safeSelectedBankId;

    if (customerId == null) {
      showSnackBar(
        message: 'Please select a customer.',
        backgroundColor: Colors.red,
      );
      return;
    }

    if (bankId == null) {
      showSnackBar(
        message: 'Please select a bank.',
        backgroundColor: Colors.red,
      );
      return;
    }

    final String amountValue = amount.text.trim();

    if (amountValue.isEmpty) {
      showSnackBar(
        message: 'Please enter the amount.',
        backgroundColor: Colors.red,
      );
      return;
    }

    final double? parsedAmount =
        double.tryParse(amountValue);

    if (parsedAmount == null || parsedAmount <= 0) {
      showSnackBar(
        message: 'Please enter a valid amount.',
        backgroundColor: Colors.red,
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      isUpdating = true;
    });

    try {
      final String? token = await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found',
        );
      }

      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      final String? username =
          prefs.getString('username');

      if (username == null || username.isEmpty) {
        throw Exception('Username not found');
      }

      final http.Response response = await http.put(
        Uri.parse(
          '$api/api/advancereceipt/view/${widget.id}/',
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {
          'customer': customerId,
          'bank': bankId.toString(),
          'amount': amountValue,
          'received_at': formatDate(selectedDate),
          'transactionID':
              transactionid.text.trim(),
          'remark': remark.text.trim(),
        },
      );

      debugPrint(
        'Update API status: ${response.statusCode}',
      );
      debugPrint(
        'Update API response: ${response.body}',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        showSnackBar(
          message:
              'Advance receipt updated successfully.',
          backgroundColor: Colors.green,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) =>
                advance_recipt_Report(),
          ),
        );
      } else {
        String errorMessage =
            'Failed to update advance receipt.';

        try {
          final dynamic errorData =
              jsonDecode(response.body);

          if (errorData is Map<String, dynamic>) {
            errorMessage =
                errorData['message']?.toString() ??
                errorData['detail']?.toString() ??
                errorMessage;
          }
        } catch (_) {
          // Keep default error message.
        }

        showSnackBar(
          message: errorMessage,
          backgroundColor: Colors.red,
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Advance receipt update error: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      showSnackBar(
        message:
            'An error occurred. Please try again.',
        backgroundColor: Colors.red,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isUpdating = false;
      });
    }
  }

  @override
  void dispose() {
    transactionid.dispose();
    amount.dispose();
    createdby.dispose();
    remark.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
        242,
        255,
        255,
        255,
      ),
      appBar: AppBar(
        title: const Text(
          'Update Recipt',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
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
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : LayoutBuilder(
              builder: (
                BuildContext context,
                BoxConstraints constraints,
              ) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior
                          .onDrag,
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        const SizedBox(height: 15),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 1,
                          ),
                          child: Container(
                            width:
                                constraints.maxWidth * 0.9,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    const Color.fromARGB(
                                  255,
                                  202,
                                  202,
                                  202,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color:
                                          const Color.fromARGB(
                                        255,
                                        2,
                                        65,
                                        96,
                                      ),
                                      border: Border.all(
                                        color:
                                            const Color.fromARGB(
                                          255,
                                          202,
                                          202,
                                          202,
                                        ),
                                      ),
                                    ),
                                    child: const Column(
                                      children: [
                                        SizedBox(height: 10),
                                        Text(
                                          'Update Recipt',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight:
                                                FontWeight.bold,
                                            color:
                                                Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 13),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Select Customer',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(
                                        10,
                                      ),
                                    ),
                                    child:
                                        DropdownButtonHideUnderline(
                                      child:
                                          DropdownButton<String>(
                                        isExpanded: true,
                                        value:
                                            safeSelectedCustomerId,
                                        hint: Text(
                                          uniqueCustomerList
                                                  .isEmpty
                                              ? 'No customers available'
                                              : 'Select Customer',
                                          style:
                                              const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                        items:
                                            uniqueCustomerList
                                                .map(
                                          (
                                            Map<String,
                                                    dynamic>
                                                customerItem,
                                          ) {
                                            return DropdownMenuItem<
                                                String>(
                                              value:
                                                  customerItem[
                                                          'id']
                                                      .toString(),
                                              child: Text(
                                                customerItem[
                                                            'name']
                                                        ?.toString() ??
                                                    'Unknown Customer',
                                                overflow:
                                                    TextOverflow
                                                        .ellipsis,
                                                style:
                                                    const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            );
                                          },
                                        ).toList(),
                                        onChanged:
                                            uniqueCustomerList
                                                    .isEmpty
                                                ? null
                                                : (
                                                    String?
                                                        value,
                                                  ) {
                                                    setState(
                                                      () {
                                                        selectedCustomerId =
                                                            value;
                                                      },
                                                    );
                                                  },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Amount',
                                    style: TextStyle(
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  TextField(
                                    controller: amount,
                                    keyboardType:
                                        const TextInputType
                                            .numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration:
                                        InputDecoration(
                                      labelText: 'Amount',
                                      hintText:
                                          'Enter your amount',
                                      labelStyle:
                                          const TextStyle(
                                        fontSize: 13,
                                      ),
                                      border:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                          10,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Payment Date',
                                    style: TextStyle(
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  InkWell(
                                    onTap: () {
                                      selectDate(context);
                                    },
                                    borderRadius:
                                        BorderRadius.circular(
                                      8,
                                    ),
                                    child: Container(
                                      width:
                                          double.infinity,
                                      height: 46,
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 16,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey,
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
                                              DateFormat(
                                                'dd/MM/yyyy',
                                              ).format(
                                                selectedDate,
                                              ),
                                              style:
                                                  const TextStyle(
                                                fontSize: 15,
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
                                          const Icon(
                                            Icons.date_range,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Created By',
                                    style: TextStyle(
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  TextField(
                                    controller: createdby,
                                    readOnly: true,
                                    decoration:
                                        InputDecoration(
                                      border:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                          10,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Bank',
                                    style: TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    height: 49,
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color:
                                            const Color.fromARGB(
                                          255,
                                          206,
                                          206,
                                          206,
                                        ),
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(
                                        10,
                                      ),
                                    ),
                                    child:
                                        DropdownButtonHideUnderline(
                                      child:
                                          DropdownButton<int>(
                                        isExpanded: true,
                                        value:
                                            safeSelectedBankId,
                                        hint: Text(
                                          uniqueBankList
                                                  .isEmpty
                                              ? 'No banks available'
                                              : 'Select Bank',
                                          style:
                                              const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                        items:
                                            uniqueBankList.map<
                                                DropdownMenuItem<
                                                    int>>(
                                          (
                                            Map<String,
                                                    dynamic>
                                                bankItem,
                                          ) {
                                            final int bankId =
                                                parseInt(
                                              bankItem['id'],
                                            )!;

                                            return DropdownMenuItem<
                                                int>(
                                              value: bankId,
                                              child: Text(
                                                bankItem['name']
                                                        ?.toString() ??
                                                    'Unknown Bank',
                                                overflow:
                                                    TextOverflow
                                                        .ellipsis,
                                                style:
                                                    const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            );
                                          },
                                        ).toList(),
                                        onChanged:
                                            uniqueBankList
                                                    .isEmpty
                                                ? null
                                                : (
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
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Transaction ID',
                                    style: TextStyle(
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
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
                                            BorderRadius.circular(
                                          10,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Remark',
                                    style: TextStyle(
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  TextField(
                                    controller: remark,
                                    maxLines: 3,
                                    decoration:
                                        InputDecoration(
                                      labelText: 'Remark',
                                      labelStyle:
                                          const TextStyle(
                                        fontSize: 13,
                                      ),
                                      border:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                          10,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Center(
                                    child: ElevatedButton(
                                      onPressed:
                                          canUpdate &&
                                                  !isUpdating
                                              ? updateexpense
                                              : null,
                                      style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty
                                                .resolveWith<
                                                    Color>(
                                          (
                                            Set<WidgetState>
                                                states,
                                          ) {
                                            if (states
                                                .contains(
                                              WidgetState
                                                  .disabled,
                                            )) {
                                              return Colors.grey;
                                            }

                                            return Colors.blue;
                                          },
                                        ),
                                        shape:
                                            WidgetStateProperty
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
                                            WidgetStateProperty
                                                .all<Size>(
                                          Size(
                                            constraints
                                                    .maxWidth *
                                                0.4,
                                            50,
                                          ),
                                        ),
                                      ),
                                      child: isUpdating
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
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
                                              'Update',
                                              style:
                                                  TextStyle(
                                                color:
                                                    Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}