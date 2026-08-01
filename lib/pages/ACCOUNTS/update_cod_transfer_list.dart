import 'dart:convert';

import 'package:beposoft/pages/ACCOUNTS/cod_transfer.dart';
import 'package:beposoft/pages/ACCOUNTS/cod_transfer_list.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/internal_tranfer.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateCodTransferList extends StatefulWidget {
  final int id;

  const UpdateCodTransferList({
    super.key,
    required this.id,
  });

  @override
  State<UpdateCodTransferList> createState() =>
      _UpdateCodTransferListState();
}

class _UpdateCodTransferListState
    extends State<UpdateCodTransferList> {
  List<Map<String, dynamic>> bank = [];
  List<Map<String, dynamic>> salesReportList = [];
  List<Map<String, dynamic>> allSalesReportList = [];

  int totalReceipts = 0;
  double totalAmount = 0.0;

  final TextEditingController uname =
      TextEditingController();

  final TextEditingController amount =
      TextEditingController();

  final TextEditingController transactionid =
      TextEditingController();

  final TextEditingController Remark =
      TextEditingController();

  String? selectedInvoiceId;
  String? selectedBankId;
  String? selectedrecieverId;

  DateTime selectedDate = DateTime.now();

  String currentDepartment = '';

  dynamic respo;

  bool isUpdating = false;

  @override
  void initState() {
    super.initState();

    initializePage();
  }

  Future<void> initializePage() async {
    await loadDepartment();

    if (!mounted) return;

    await getreciptReport();

    if (!mounted) return;

    await getbank();
  }

  Future<void> loadDepartment() async {
    final String? department =
        await getdepFromPrefs();

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

  Future<String?> getTokenFromPrefs() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  Future<String?> gettokenFromPrefs() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('token');
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
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
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

  Future<void> updatebanktransfer() async {
    if (!canUpdate || isUpdating) {
      return;
    }

    if (selectedBankId == null ||
        selectedBankId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Please select sending bank.',
          ),
        ),
      );

      return;
    }

    if (selectedrecieverId == null ||
        selectedrecieverId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Please select receiver bank.',
          ),
        ),
      );

      return;
    }

    if (!mounted) return;

    setState(() {
      isUpdating = true;
    });

    try {
      final String? token =
          await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found',
        );
      }

      final http.Response response =
          await http.put(
        Uri.parse(
          '$api/api/cod/transfers/${widget.id}/',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "amount": amount.text,
          "transactionID": transactionid.text,
          "sender_bank":
              int.tryParse(selectedBankId ?? '0'),
          "receiver_bank":
              int.tryParse(selectedrecieverId ?? '0'),
          "description": Remark.text,
          "created_at":
              selectedDate.toIso8601String(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        try {
          final dynamic responseData =
              jsonDecode(response.body);

          if (responseData is Map<String, dynamic>) {
            respo = responseData['data'] ??
                responseData;
          } else {
            respo = responseData;
          }
        } catch (_) {
          respo = response.body;
        }

        await AddStatusTime(context);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Transfer updated successfully',
            ),
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) =>
                cod_transfer_list(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to update Transfer',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      debugPrint(
        'Error updating transfer: $error',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error updating transfer',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isUpdating = false;
      });
    }
  }

  Future<void> getbank() async {
    final String? token =
        await getTokenFromPrefs();

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

  void _updateTotals() {
    int tempTotalReceipts = 0;
    double tempTotalAmount = 0.0;

    for (final Map<String, dynamic> reportData
        in salesReportList) {
      tempTotalReceipts++;

      final dynamic rawAmount =
          reportData['amount'];

      if (rawAmount is num) {
        tempTotalAmount += rawAmount.toDouble();
      } else {
        tempTotalAmount +=
            double.tryParse(
                  rawAmount?.toString() ?? '0',
                ) ??
                0.0;
      }
    }

    if (!mounted) return;

    setState(() {
      totalReceipts = tempTotalReceipts;
      totalAmount = tempTotalAmount;
    });
  }

  String formatCreatedAtDate(
    Map<String, dynamic> reportData,
  ) {
    final dynamic rawDate =
        reportData['created_at'];

    if (rawDate == null) {
      return '';
    }

    final DateTime? parsedDate =
        DateTime.tryParse(
      rawDate.toString(),
    );

    if (parsedDate == null) {
      return '';
    }

    return DateFormat('yyyy-MM-dd').format(
      parsedDate,
    );
  }

  Future<void> getreciptReport() async {
    try {
      final String? token =
          await getTokenFromPrefs();

      final http.Response response =
          await http.get(
        Uri.parse(
          '$api/api/cod/transfers/',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic parsed =
            jsonDecode(response.body);

        final List<Map<String, dynamic>>
            reciptList = [];

        if (parsed is List) {
          for (final dynamic reportData
              in parsed) {
            if (reportData is! Map) {
              continue;
            }

            reciptList.add({
              'id': reportData['id'],
              'transactionID':
                  reportData['transactionID'] ?? '',
              'amount': double.tryParse(
                    reportData['amount'].toString(),
                  ) ??
                  0.0,
              'bank': reportData['bank'],
              'receiver_bank_name':
                  reportData[
                      'receiver_bank_name'],
              'sender_bank_name':
                  reportData['sender_bank_name'],
              'receiver_bank':
                  reportData['receiver_bank'],
              'created_by_name':
                  reportData['created_by_name'] ??
                      '',
              'remark':
                  reportData['remark'] ?? '',
              'created_at':
                  reportData['created_at'],
            });

            if (reportData['id'] == widget.id) {
              if (!mounted) return;

              setState(() {
                amount.text =
                    reportData['amount'].toString();

                transactionid.text =
                    reportData['transactionID'] ??
                        '';

                selectedBankId =
                    reportData['sender_bank']
                        ?.toString();

                selectedrecieverId =
                    reportData['receiver_bank']
                        ?.toString();

                Remark.text =
                    reportData['description'] ?? '';

                uname.text =
                    reportData['created_by_name'] ??
                        '';

                selectedDate =
                    DateTime.tryParse(
                          reportData['created_at']
                                  ?.toString() ??
                              '',
                        ) ??
                        DateTime.now();
              });
            }
          }
        }

        if (!mounted) return;

        setState(() {
          allSalesReportList = reciptList;

          salesReportList =
              List<Map<String, dynamic>>.from(
            allSalesReportList,
          );
        });

        _updateTotals();
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to fetch data',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      debugPrint(
        'Error fetching transfer data: $error',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error fetching data',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<String?> getdepFromPrefs() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('department');
  }

  Future<String?> getusername() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('username');
  }

  Future<void> _navigateBack() async {
    final String? dep =
        await getdepFromPrefs();

    if (!mounted) return;

    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              bdo_dashbord(),
        ),
      );
    } else if (dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              ceo_dashboard(),
        ),
      );
    } else if (dep == "CSO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              cso_dashboard(),
        ),
      );
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              bdm_dashbord(),
        ),
      );
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              WarehouseDashboard(),
        ),
      );
    } else if (dep == "CEO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              ceo_dashboard(),
        ),
      );
    } else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              WarehouseAdmin(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>
              dashboard(),
        ),
      );
    }
  }

  int? _parseBankId(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  String? get safeSelectedBankId {
    if (selectedBankId == null) {
      return null;
    }

    final bool exists = bank.any(
      (Map<String, dynamic> bankItem) {
        return bankItem['id'].toString() ==
            selectedBankId;
      },
    );

    return exists ? selectedBankId : null;
  }

  String? get safeSelectedReceiverBankId {
    if (selectedrecieverId == null) {
      return null;
    }

    final bool exists = bank.any(
      (Map<String, dynamic> bankItem) {
        return bankItem['id'].toString() ==
            selectedrecieverId;
      },
    );

    return exists
        ? selectedrecieverId
        : null;
  }

  @override
  void dispose() {
    uname.dispose();
    amount.dispose();
    transactionid.dispose();
    Remark.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor:
            const Color.fromARGB(
          242,
          255,
          255,
          255,
        ),
        appBar: AppBar(
          title: const Text(
            "Update COD Transfer",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back),
            onPressed: _navigateBack,
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
        body: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.only(
              bottom: 55,
            ),
            child: Container(
              child: Column(
                children: [
                  const SizedBox(
                    height: 15,
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      right: 10,
                      top: 10,
                      left: 10,
                    ),
                    child: Container(
                      width: 600,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color.fromARGB(
                          255,
                          34,
                          165,
                          246,
                        ),
                        border:
                            Border.all(
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
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            "COD Transfer Update",
                            style:
                                TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Colors.white,
                            ),
                          ),
                          SizedBox(
                            height: 13,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 25,
                      left: 15,
                      right: 15,
                    ),
                    child: Container(
                      width: 700,
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
                            const EdgeInsets.only(
                          left: 10,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const SizedBox(
                              height: 10,
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            const Text(
                              "Amount",
                              style:
                                  TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.bold,
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
                              child: TextField(
                                controller:
                                    amount,
                                decoration:
                                    InputDecoration(
                                  labelText:
                                      'Amount',
                                  labelStyle:
                                      const TextStyle(
                                    fontSize:
                                        12,
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
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            const Text(
                              "Sending Bank",
                              style:
                                  TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.bold,
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
                                        Colors.grey,
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
                                      safeSelectedBankId,
                                  hint:
                                      const Text(
                                    'Select Bank',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          12,
                                    ),
                                  ),
                                  items:
                                      bank.map(
                                    (
                                      Map<String,
                                              dynamic>
                                          bankItem,
                                    ) {
                                      return DropdownMenuItem<
                                          String>(
                                        value: bankItem[
                                                'id']
                                            .toString(),
                                        child:
                                            Text(
                                          '${bankItem['name']}',
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
                                      (String?
                                          value) {
                                    setState(
                                      () {
                                        selectedBankId =
                                            value;
                                      },
                                    );
                                  },
                                  underline:
                                      const SizedBox(),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            const Text(
                              "Reciever Bank",
                              style:
                                  TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.bold,
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
                                        Colors.grey,
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
                                      safeSelectedReceiverBankId,
                                  hint:
                                      const Text(
                                    'Select Bank',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          12,
                                    ),
                                  ),
                                  items:
                                      bank.map(
                                    (
                                      Map<String,
                                              dynamic>
                                          bankItem,
                                    ) {
                                      return DropdownMenuItem<
                                          String>(
                                        value: bankItem[
                                                'id']
                                            .toString(),
                                        child:
                                            Text(
                                          '${bankItem['name']}',
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
                                      (String?
                                          value) {
                                    setState(
                                      () {
                                        selectedrecieverId =
                                            value;
                                      },
                                    );
                                  },
                                  underline:
                                      const SizedBox(),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            const Text(
                              "Remark",
                              style:
                                  TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.bold,
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
                              child: TextField(
                                controller:
                                    Remark,
                                decoration:
                                    InputDecoration(
                                  labelText:
                                      'Remark',
                                  labelStyle:
                                      const TextStyle(
                                    fontSize:
                                        12,
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
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            const Text(
                              "Date",
                              style:
                                  TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.bold,
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
                              child:
                                  GestureDetector(
                                onTap:
                                    () async {
                                  final DateTime?
                                      pickedDate =
                                      await showDatePicker(
                                    context:
                                        context,
                                    initialDate:
                                        selectedDate,
                                    firstDate:
                                        DateTime(
                                      2000,
                                    ),
                                    lastDate:
                                        DateTime(
                                      2100,
                                    ),
                                  );

                                  if (!mounted) return;

                                  if (pickedDate !=
                                      null) {
                                    setState(
                                      () {
                                        selectedDate =
                                            pickedDate;
                                      },
                                    );
                                  }
                                },
                                child:
                                    AbsorbPointer(
                                  child:
                                      TextField(
                                    readOnly:
                                        true,
                                    decoration:
                                        InputDecoration(
                                      labelText:
                                          'Date',
                                      labelStyle:
                                          const TextStyle(
                                        fontSize:
                                            12,
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
                                        vertical:
                                            8,
                                      ),
                                    ),
                                    controller:
                                        TextEditingController(
                                      text:
                                          DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(
                                        selectedDate,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            const Text(
                              "Name",
                              style:
                                  TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.bold,
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
                              child: TextField(
                                controller:
                                    TextEditingController(
                                  text:
                                      uname.text,
                                ),
                                readOnly: true,
                                decoration:
                                    InputDecoration(
                                  labelText:
                                      'Name',
                                  labelStyle:
                                      const TextStyle(
                                    fontSize:
                                        12,
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
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                ),
                                SizedBox(
                                  width: 270,
                                  child:
                                      ElevatedButton(
                                    onPressed:
                                        canUpdate &&
                                                !isUpdating
                                            ? updatebanktransfer
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
                                          if (states
                                              .contains(
                                            MaterialState
                                                .disabled,
                                          )) {
                                            return Colors
                                                .grey;
                                          }

                                          return const Color
                                              .fromARGB(
                                            255,
                                            64,
                                            176,
                                            251,
                                          );
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
                                              .all<
                                                  Size>(
                                        const Size(
                                          95,
                                          15,
                                        ),
                                      ),
                                    ),
                                    child:
                                        isUpdating
                                            ? const SizedBox(
                                                width:
                                                    18,
                                                height:
                                                    18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth:
                                                      2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    Colors
                                                        .white,
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
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}