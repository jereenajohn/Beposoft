import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/update_bank.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class cod_transfer extends StatefulWidget {
  const cod_transfer({super.key});

  @override
  State<cod_transfer> createState() => cod_transferState();
}

class cod_transferState extends State<cod_transfer> {
  drower d = drower();

  Widget _buildDropdownTile(
    BuildContext context,
    String title,
    List<String> options,
  ) {
    return ExpansionTile(
      title: Text(title),
      children: options.map((option) {
        return ListTile(
          title: Text(option),
          onTap: () {
            Navigator.pop(context);

            d.navigateToSelectedPage(
              context,
              option,
            );
          },
        );
      }).toList(),
    );
  }

  TextEditingController uname = TextEditingController();
  TextEditingController amount = TextEditingController();
  TextEditingController transactionid = TextEditingController();
  TextEditingController Remark = TextEditingController();

  List<Map<String, dynamic>> bank = [];
  List<Map<String, dynamic>> orders = [];

  DateTime selectedDate = DateTime.now();
  DateTime selectedDate1 = DateTime.now();

  String? selectedInvoiceId;
  String? selectedBankId;
  String? selectedrecieverId;

  String? selectedReceiptType;

  final List<String> receiptTypes = [
    'Order Receipt',
    'Advance receipt',
    'other Receipt',
  ];

  List<Map<String, dynamic>> customer = [];

  String? selectedCustomerId;

  dynamic respo;

  Future<String?> gettoken() async {
    SharedPreferences pref =
        await SharedPreferences.getInstance();

    return pref.getString('token');
  }

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();

    getbank();
    fetchOrderData();
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  Future<void> fetchOrderData() async {
    try {
      final token = await getTokenFromPrefs();
      final dep = await getdepFromPrefs();

      if (token == null || token.isEmpty) {
        return;
      }

      final jwt = JWT.decode(token);
      var name = jwt.payload['name'];

      String url = '$api/api/orders/';

      var response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            jsonDecode(response.body);

        List ordersData = [];

        final dynamic resultData =
            responseData['results'];

        if (resultData is List) {
          ordersData = resultData;
        } else if (resultData is Map<String, dynamic> &&
            resultData['results'] is List) {
          ordersData =
              resultData['results'] as List;
        }

        List<Map<String, dynamic>> newOrders = [];

        for (var orderData in ordersData) {
          String customerName = '';

          final dynamic orderCustomer =
              orderData['customer'];

          if (orderCustomer is Map) {
            customerName =
                orderCustomer['name']?.toString() ?? '';
          } else {
            customerName =
                orderData['customer_name']?.toString() ??
                    orderCustomer?.toString() ??
                    '';
          }

          newOrders.add({
            'id': orderData['id'],
            'invoice': orderData['invoice'],
            'customer': customerName,
          });
        }

        if (!mounted) return;

        setState(() {
          orders = newOrders;
          uname.text = name?.toString() ?? '';
        });
      } else {
        throw Exception(
          "Failed to load order data",
        );
      }
    } catch (error) {
      debugPrint(
        'Error loading order data: $error',
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

  Future<void> Addtransfer(
    BuildContext scaffoldContext,
  ) async {
    final token = await gettoken();

    try {
      final token =
          await getTokenFromPrefs();

      if (token == null || token.isEmpty) {
        return;
      }

      final jwt = JWT.decode(token);
      var name = jwt.payload['name'];

      String formattedDate =
          DateFormat('yyyy-MM-dd').format(
        selectedDate,
      );

      String formattedDate1 =
          DateFormat('yyyy-MM-dd').format(
        selectedDate1,
      );

      final response = await http.post(
        Uri.parse(
          '$api/api/cod/transfers/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount.text,
          'sender_bank': selectedBankId,
          'receiver_bank': selectedrecieverId,
          'created_at': formattedDate,
          'created_end': formattedDate1,
          'description': Remark.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        try {
          final dynamic responseData =
              jsonDecode(response.body);

          if (responseData is Map<String, dynamic>) {
            respo = responseData['data'] ??
                responseData;
          } else {
            respo = responseData;
          }
        } catch (e) {
          respo = response.body;
        }

        await AddStatusTime(
          scaffoldContext,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(
          scaffoldContext,
        ).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              'Receipt added Successfully.',
            ),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const cod_transfer(),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          scaffoldContext,
        ).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Adding receipt failed.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'Error adding COD transfer: $e',
      );
    }
  }

  void logout() async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.remove('userId');
    await prefs.remove('token');

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Logged out successfully',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => login(),
      ),
    );
  }

  Future<void> getbank() async {
    final token = await gettoken();

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
        final parsed =
            jsonDecode(response.body);

        var productsData = parsed['data'];

        for (var productData in productsData) {
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
        'Error loading banks: $e',
      );
    }
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('department');
  }

  Future<String?> getusername() async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('username');
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();

    if (!mounted) return;

    if (dep == "BDO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              bdo_dashbord(),
        ),
      );
    } else if (dep == "BDM") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              bdm_dashbord(),
        ),
      );
    } else if (dep == "warehouse") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              WarehouseDashboard(),
        ),
      );
    } else if (dep == "CEO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ceo_dashboard(),
        ),
      );
    } else if (dep == "COO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ceo_dashboard(),
        ),
      );
    } else if (dep == "CSO") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              cso_dashboard(),
        ),
      );
    } else if (dep == "Warehouse Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              WarehouseAdmin(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              dashboard(),
        ),
      );
    }
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
        _navigateBack();
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
            "COD Transfer",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
            ),
            onPressed: () async {
              final dep =
                  await getdepFromPrefs();

              if (!mounted) return;

              if (dep == "BDO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        bdo_dashbord(),
                  ),
                );
              } else if (dep == "BDM") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        bdm_dashbord(),
                  ),
                );
              } else if (dep == "warehouse") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WarehouseDashboard(),
                  ),
                );
              } else if (dep == "COO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ceo_dashboard(),
                  ),
                );
              } else if (dep == "CSO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        cso_dashboard(),
                  ),
                );
              } else if (dep == "CEO") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ceo_dashboard(),
                  ),
                );
              } else if (dep ==
                  "Warehouse Admin") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WarehouseAdmin(),
                  ),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        dashboard(),
                  ),
                );
              }
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
                            "COD Transfer",
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
                              "Reciever Bank",
                              style:
                                  TextStyle(
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
                                      selectedrecieverId,
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
                                      (value) {
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
                              "Sending Bank",
                              style:
                                  TextStyle(
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
                                      selectedBankId,
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
                                      (value) {
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
                              "Remark",
                              style:
                                  TextStyle(
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
                              "Receiver Date",
                              style:
                                  TextStyle(
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
                              child:
                                  GestureDetector(
                                onTap:
                                    () async {
                                  DateTime?
                                      pickedDate =
                                      await showDatePicker(
                                    context:
                                        context,
                                    initialDate:
                                        selectedDate1,
                                    firstDate:
                                        DateTime(
                                      2000,
                                    ),
                                    lastDate:
                                        DateTime(
                                      2100,
                                    ),
                                  );

                                  if (pickedDate !=
                                      null) {
                                    setState(
                                      () {
                                        selectedDate1 =
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
                                        selectedDate1,
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
                              "Sender Date",
                              style:
                                  TextStyle(
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
                              child:
                                  GestureDetector(
                                onTap:
                                    () async {
                                  DateTime?
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
                            const SizedBox(
                              height: 10,
                            ),
                            const Text(
                              "Name",
                              style:
                                  TextStyle(
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
                                        () {
                                      Addtransfer(
                                        context,
                                      );
                                    },
                                    style:
                                        ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty
                                              .all<
                                                  Color>(
                                        const Color
                                            .fromARGB(
                                          255,
                                          64,
                                          176,
                                          251,
                                        ),
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
                                        const Text(
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