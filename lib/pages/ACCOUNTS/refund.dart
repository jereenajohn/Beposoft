import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/update_bank.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:beposoft/pages/api.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class addrefund extends StatefulWidget {
  const addrefund({super.key});

  @override
  State<addrefund> createState() => _addrefundState();
}

class _addrefundState extends State<addrefund> {
  drower d = drower();

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

  TextEditingController uname = TextEditingController();
  TextEditingController amount = TextEditingController();
  TextEditingController transactionid = TextEditingController();
  TextEditingController Remark = TextEditingController();

  TextEditingController invoiceSearchController = TextEditingController();
  TextEditingController customerSearchController = TextEditingController();

  List<Map<String, dynamic>> bank = [];
  DateTime selectedDate = DateTime.now();

  String? selectedInvoiceId;
  String? selectedBankId;
  String? selectedCustomerId;
  String? selectedReceiptType;

  var respo;

  final List<String> receiptTypes = ['Order Refund', 'Advance Refund'];

  Future<String?> gettoken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString('token');
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  void initState() {
    super.initState();
    getbank();
    loadLoggedUserName();
  }

  @override
  void dispose() {
    uname.dispose();
    amount.dispose();
    transactionid.dispose();
    Remark.dispose();
    invoiceSearchController.dispose();
    customerSearchController.dispose();
    super.dispose();
  }

  Future<void> loadLoggedUserName() async {
    try {
      final token = await getTokenFromPrefs();
      if (token != null) {
        final jwt = JWT.decode(token);
        setState(() {
          uname.text = jwt.payload['name'] ?? '';
        });
      }
    } catch (e) {
    }
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
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'] ?? [];

        for (var productData in productsData) {
          banklist.add({
            'id': productData['id'],
            'name': productData['name'],
            'branch': productData['branch']
          });
        }

        setState(() {
          bank = banklist;
        });
      }
    } catch (e) {
    }
  }

  Future<List<Map<String, dynamic>>> searchCustomers(String search) async {
    try {
      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/customers/?search=$search'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

     

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        List results = parsed['results'] ?? [];

        return results.map<Map<String, dynamic>>((cust) {
          return {
            "id": cust['id'],
            "name": cust['name'] ?? '',
            "created_at": cust['created_at'],
          };
        }).toList();
      }
    } catch (e) {
    }

    return [];
  }

  Future<List<Map<String, dynamic>>> searchInvoices(String search) async {
    try {
      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/orders/?search=$search'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

    

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List results = [];

        if (parsed['results'] is Map && parsed['results']['results'] is List) {
          results = parsed['results']['results'];
        } else if (parsed['results'] is List) {
          results = parsed['results'];
        } else if (parsed['data'] is List) {
          results = parsed['data'];
        }

        return results.map<Map<String, dynamic>>((order) {
          return {
            "id": order['id'],
            "invoice": order['invoice'] ?? '',
            "customer": order['customer'] != null
                ? (order['customer']['name'] ?? '')
                : '',
          };
        }).toList();
      }
    } catch (e) {
    }

    return [];
  }

  Future<void> Addrefundlog(BuildContext scaffoldContext, dynamic respo) async {
    final token = await getTokenFromPrefs();

    try {
      final response = await http.post(
        Uri.parse('$api/api/datalog/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'before_data': {"status": "Refund added"},
          'after_data': {
            'refund_no': respo['refund_no'],
            'customer_name': respo['customer_name'],
            'amount': respo['amount'],
            'created_by': respo['created_name'],
            'date': respo['date'],
            'invoice': respo['invoice'],
          },
          'order': "",
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Note log added successfully.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Log creation failed.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Unexpected error while adding log'),
        ),
      );
    }
  }

  Future<void> AddRefund(BuildContext scaffoldContext) async {
    try {
      final token = await getTokenFromPrefs();
      final jwt = JWT.decode(token!);
      var name = jwt.payload['name'];

      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

      final response = await http.post(
        Uri.parse('$api/api/refund/receipts/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'transactionID': transactionid.text,
          'customer': selectedCustomerId,
          'invoice': selectedReceiptType == 'Order Refund'
              ? selectedInvoiceId
              : null,
          'amount': amount.text,
          'bank': selectedBankId,
          'date': formattedDate,
          'created_by': name,
          'note': Remark.text
        }),
      );

    

      if (response.statusCode == 200 || response.statusCode == 201) {
        var Data = jsonDecode(response.body);
        respo = Data['data'];

        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Refund added Successfully.'),
          ),
        );

        await Addrefundlog(scaffoldContext, respo);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const addrefund()),
        );
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Adding refund failed. ${response.body}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Unexpected error while adding refund'),
        ),
      );
    }
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

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<String?> getusername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(242, 255, 255, 255),
        appBar: AppBar(
          title: const Text(
            "Add Refund",
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
            },
          ),
          actions: [
            IconButton(
              icon: Image.asset('lib/assets/profile.png'),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 55),
            child: Column(
              children: [
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 10, left: 10),
                  child: Container(
                    width: 600,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 34, 165, 246),
                      border: Border.all(
                        color: const Color.fromARGB(255, 202, 202, 202),
                      ),
                    ),
                    child: const Column(
                      children: [
                        SizedBox(height: 10),
                        Text(
                          "Add Refund",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 13),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 25, left: 15, right: 15),
                  child: Container(
                    width: 700,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: const Color.fromARGB(255, 202, 202, 202),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Refund Type",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedReceiptType,
                                hint: const Text(
                                  'Select Refund Type',
                                  style: TextStyle(fontSize: 12.0),
                                ),
                                items: receiptTypes.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(
                                      type,
                                      style: const TextStyle(fontSize: 12.0),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedReceiptType = value;

                                    if (selectedReceiptType == 'Advance Refund') {
                                      selectedInvoiceId = null;
                                      invoiceSearchController.clear();
                                    }
                                  });
                                },
                                underline: const SizedBox(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          if (selectedReceiptType == 'Order Refund') ...[
                            const Text(
                              "Select Invoice",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TypeAheadField<Map<String, dynamic>>(
                                suggestionsCallback: (pattern) async {
                                  return await searchInvoices(pattern);
                                },
                                builder: (context, controller, focusNode) {
                                  if (invoiceSearchController.text.isNotEmpty &&
                                      controller.text != invoiceSearchController.text) {
                                    controller.text = invoiceSearchController.text;
                                    controller.selection = TextSelection.fromPosition(
                                      TextPosition(offset: controller.text.length),
                                    );
                                  }

                                  return TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: InputDecoration(
                                      labelText: "Select Invoice",
                                      labelStyle: const TextStyle(fontSize: 12.0),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                        borderSide: const BorderSide(color: Colors.grey),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                        horizontal: 10,
                                      ),
                                    ),
                                  );
                                },
                                itemBuilder: (context, suggestion) {
                                  return ListTile(
                                    title: Text(
                                      suggestion['invoice'] ?? '',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    subtitle: Text(
                                      suggestion['customer'] ?? '',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  );
                                },
                                onSelected: (suggestion) {
                                  setState(() {
                                    selectedInvoiceId = suggestion['id'].toString();
                                    invoiceSearchController.text =
                                        "${suggestion['invoice']} - ${suggestion['customer']}";
                                  });
                                },
                                emptyBuilder: (context) => const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text(
                                    "No invoice found",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          const Text(
                            "Select Customer",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TypeAheadField<Map<String, dynamic>>(
                              suggestionsCallback: (pattern) async {
                                return await searchCustomers(pattern);
                              },
                              builder: (context, controller, focusNode) {
                                if (customerSearchController.text.isNotEmpty &&
                                    controller.text != customerSearchController.text) {
                                  controller.text = customerSearchController.text;
                                  controller.selection = TextSelection.fromPosition(
                                    TextPosition(offset: controller.text.length),
                                  );
                                }

                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: "Select Customer",
                                    labelStyle: const TextStyle(fontSize: 12.0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: const BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 10,
                                    ),
                                  ),
                                );
                              },
                              itemBuilder: (context, suggestion) {
                                return ListTile(
                                  title: Text(
                                    suggestion['name'] ?? '',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                              onSelected: (suggestion) {
                                setState(() {
                                  selectedCustomerId = suggestion['id'].toString();
                                  customerSearchController.text =
                                      suggestion['name'] ?? '';
                                });
                              },
                              emptyBuilder: (context) => const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Text(
                                  "No customer found",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),

                          const Text(
                            "Amount",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: TextField(
                              controller: amount,
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                labelStyle: const TextStyle(fontSize: 12.0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          const Text(
                            "Transaction Id",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: TextField(
                              controller: transactionid,
                              decoration: InputDecoration(
                                labelText: 'Transaction Id',
                                labelStyle: const TextStyle(fontSize: 12.0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          const Text(
                            "Bank",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedBankId,
                                hint: const Text(
                                  'Select Bank',
                                  style: TextStyle(fontSize: 12.0),
                                ),
                                items: bank.map((bankItem) {
                                  return DropdownMenuItem<String>(
                                    value: bankItem['id'].toString(),
                                    child: Text(
                                      '${bankItem['name']}',
                                      style: const TextStyle(fontSize: 12.0),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedBankId = value;
                                  });
                                },
                                underline: const SizedBox(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          const Text(
                            "Date",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () async {
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (pickedDate != null) {
                                  setState(() {
                                    selectedDate = pickedDate;
                                  });
                                }
                              },
                              child: AbsorbPointer(
                                child: TextField(
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Date',
                                    labelStyle: const TextStyle(fontSize: 12.0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: const BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 8.0),
                                  ),
                                  controller: TextEditingController(
                                    text: DateFormat('yyyy-MM-dd')
                                        .format(selectedDate),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          const Text(
                            "Name",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: TextField(
                              controller: TextEditingController(
                                text: uname.text,
                              ),
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Name',
                                labelStyle: const TextStyle(fontSize: 12.0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          const Text(
                            "Remark",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: TextField(
                              controller: Remark,
                              maxLines: 3,
                              keyboardType: TextInputType.multiline,
                              decoration: InputDecoration(
                                labelText: 'Remark',
                                labelStyle: const TextStyle(fontSize: 12.0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 10.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(width: 20),
                              SizedBox(
                                width: 270,
                                child: ElevatedButton(
                                  onPressed: () {
                                    AddRefund(context);
                                  },
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      const Color.fromARGB(255, 64, 176, 251),
                                    ),
                                    shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    fixedSize:
                                        MaterialStateProperty.all<Size>(
                                      const Size(95, 15),
                                    ),
                                  ),
                                  child: const Text(
                                    "Submit",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
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
    );
  }
}