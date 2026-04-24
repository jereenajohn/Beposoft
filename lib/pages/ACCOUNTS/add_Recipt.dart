import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:intl/intl.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:beposoft/pages/api.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class add_receipt extends StatefulWidget {
  const add_receipt({super.key});

  @override
  State<add_receipt> createState() => _add_receiptState();
}

class _add_receiptState extends State<add_receipt> {
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

  List<Map<String, dynamic>> bank = [];
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> customer = [];

  DateTime selectedDate = DateTime.now();

  String? selectedInvoiceId;
  String? selectedInvoiceLabel;

  String? selectedBankId;

  String? selectedCustomerId;
  String? selectedCustomerName;

  var respo;

  String? selectedReceiptType;
  final List<String> receiptTypes = [
    'Order Receipt',
    'Advance receipt',
    'other Receipt'
  ];

  bool isLoadingOrders = false;
  bool isLoadingCustomers = false;

  @override
  void initState() {
    super.initState();
    fetchOrderData();
    getbank();
    getcustomer();
  }

  Future<String?> gettoken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString('token');
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<String?> getusername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<void> getcustomer() async {
    try {
      final token = await getTokenFromPrefs();
      final jwt = JWT.decode(token!);
      var name = jwt.payload['name'];

      var response = await http.get(
        Uri.parse('$api/api/customers/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        List productsData = parsed['results'] ?? [];

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
          uname.text = name;
        });
      } else {
        throw Exception("Failed to load customer data");
      }
    } catch (error) {
    }
  }

  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    try {
      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/customers/?search=$query'),
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
            'id': cust['id'],
            'name': cust['name'],
            'created_at': cust['created_at'],
            'phone': cust['phone'],
            'state_name': cust['state_name'],
          };
        }).toList();
      }
    } catch (e) {
    }

    return [];
  }

  Future<void> fetchOrderData() async {
    try {
      final token = await getTokenFromPrefs();
      final jwt = JWT.decode(token!);
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
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        final List ordersData = responseData['results']?['results'] ?? [];

        List<Map<String, dynamic>> newOrders = [];

        for (var orderData in ordersData) {
          newOrders.add({
            'id': orderData['id'],
            'invoice': orderData['invoice'] ?? '',
            'customer': orderData['customer']?['name'] ?? '',
            'customerID': orderData['customerID'],
            'order_date': orderData['order_date'],
            'total_amount': orderData['total_amount'],
          });
        }

        setState(() {
          orders = newOrders;
          uname.text = name;
        });

      } else {
        throw Exception("Failed to load order data");
      }
    } catch (error) {
    }
  }

  Future<List<Map<String, dynamic>>> searchOrders(String query) async {
    try {
      final token = await getTokenFromPrefs();

      final response = await http.get(
        Uri.parse('$api/api/orders/?search=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

    

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        List results = parsed['results']?['results'] ?? [];

        return results.map<Map<String, dynamic>>((order) {
          return {
            'id': order['id'],
            'invoice': order['invoice'] ?? '',
            'customer': order['customer']?['name'] ?? '',
            'customerID': order['customerID'],
            'order_date': order['order_date'],
            'total_amount': order['total_amount'],
          };
        }).toList();
      }
    } catch (e) {
    }

    return [];
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
        var productsData = parsed['data'];

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

  Future<void> AddStatusTime(BuildContext scaffoldContext) async {
    final token = await getTokenFromPrefs();
    try {
      final response = await http.post(
        Uri.parse('$api/api/datalog/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'before_data': {"Action": "Recipt added "},
          'after_data': {"Data": "$respo"},
          'order': "",
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('time added Successfully.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Adding time failed.'),
          ),
        );
      }
    } catch (e) {
    }
  }

  Future<void> AddReceipt(BuildContext scaffoldContext) async {
    try {
      final token = await getTokenFromPrefs();
      final jwt = JWT.decode(token!);
      var name = jwt.payload['name'];

      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

      final response = await http.post(
        Uri.parse('$api/api/payment/$selectedInvoiceId/reciept/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount.text,
          'bank': selectedBankId,
          'transactionID': transactionid.text,
          'received_at': formattedDate,
          'created_by': name,
          'remark': Remark.text
        }),
      );

      if (response.statusCode == 200) {
        var Data = jsonDecode(response.body);
        respo = Data['data'];
        AddStatusTime(scaffoldContext);

        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Receipt added Successfully.'),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const add_receipt()),
        );
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Adding receipt failed.'),
          ),
        );
      }
    } catch (e) {
    }
  }

  Future<void> AddReceipt2(BuildContext scaffoldContext) async {
    try {
      final token = await getTokenFromPrefs();

      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

      final response = await http.post(
        Uri.parse('$api/api/advancereceipt/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'customer': selectedCustomerId,
          'amount': amount.text,
          'bank': selectedBankId,
          'transactionID': transactionid.text,
          'received_at': formattedDate,
          'remark': Remark.text
        }),
      );

      if (response.statusCode == 200) {
        var Data = jsonDecode(response.body);
        respo = Data['data'];
        AddStatusTime(scaffoldContext);

        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Receipt added Successfully.'),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const add_receipt()),
        );
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Adding receipt failed.'),
          ),
        );
      }
    } catch (e) {
    }
  }

  Future<void> AddReceipt3(BuildContext scaffoldContext) async {
    try {
      final token = await getTokenFromPrefs();

      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

      final response = await http.post(
        Uri.parse('$api/api/bank-receipts/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount.text,
          'bank': selectedBankId,
          'transactionID': transactionid.text,
          'received_at': formattedDate,
          'remark': Remark.text
        }),
      );

      if (response.statusCode == 200) {
        var Data = jsonDecode(response.body);
        respo = Data['data'];
        AddStatusTime(scaffoldContext);

        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Receipt added Successfully.'),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const add_receipt()),
        );
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Adding receipt failed.'),
          ),
        );
      }
    } catch (e) {
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

  Future<void> _openCustomerSearch() async {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> results = List.from(customer);
    bool loading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> doSearch(String value) async {
              setSheetState(() {
                loading = true;
              });

              final data = await searchCustomers(value);

              setSheetState(() {
                results = data;
                loading = false;
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      onChanged: (value) async {
                        await doSearch(value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search Customer',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : results.isEmpty
                              ? const Center(child: Text("No customer found"))
                              : ListView.builder(
                                  itemCount: results.length,
                                  itemBuilder: (context, index) {
                                    final cust = results[index];
                                    return ListTile(
                                      title: Text(cust['name'] ?? ''),
                                      subtitle: Text(
                                        '${cust['phone'] ?? ''} ${cust['state_name'] ?? ''}',
                                      ),
                                      onTap: () {
                                        setState(() {
                                          selectedCustomerId =
                                              cust['id'].toString();
                                          selectedCustomerName = cust['name'];
                                        });
                                        Navigator.pop(sheetContext);
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

  Future<void> _openInvoiceSearch() async {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> results = List.from(orders);
    bool loading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> doSearch(String value) async {
              if (value.trim().isEmpty) {
                setSheetState(() {
                  results = List.from(orders);
                  loading = false;
                });
                return;
              }

              setSheetState(() {
                loading = true;
              });

              final data = await searchOrders(value);

              setSheetState(() {
                results = data;
                loading = false;
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      onChanged: (value) async {
                        await doSearch(value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search Invoice / Customer',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : results.isEmpty
                              ? const Center(child: Text("No invoice found"))
                              : ListView.builder(
                                  itemCount: results.length,
                                  itemBuilder: (context, index) {
                                    final order = results[index];
                                    return ListTile(
                                      title: Text(order['invoice'] ?? ''),
                                      subtitle: Text(order['customer'] ?? ''),
                                      trailing: Text(
                                        '${order['total_amount'] ?? ''}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          selectedInvoiceId =
                                              order['id'].toString();
                                          selectedInvoiceLabel =
                                              '${order['invoice']} - ${order['customer']}';
                                        });
                                        Navigator.pop(sheetContext);
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

  Widget _buildSearchField({
    required String title,
    required String hint,
    required String? value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AbsorbPointer(
          child: TextField(
            controller: TextEditingController(text: value ?? ''),
            readOnly: true,
            decoration: InputDecoration(
              labelText: hint,
              labelStyle: const TextStyle(fontSize: 12.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              suffixIcon: const Icon(Icons.arrow_drop_down),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
            ),
          ),
        ),
      ),
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
        backgroundColor: const Color.fromARGB(242, 255, 255, 255),
        appBar: AppBar(
          title: const Text(
            "Add Bank",
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
                          "Add Receipt",
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
                      padding: const EdgeInsets.only(left: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          const Text(
                            "Receipt Type",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedReceiptType,
                                hint: const Text(
                                  'Select Receipt Type',
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
                                    selectedInvoiceId = null;
                                    selectedInvoiceLabel = null;
                                    selectedCustomerId = null;
                                    selectedCustomerName = null;
                                  });
                                },
                                underline: const SizedBox(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (selectedReceiptType == 'Order Receipt') ...[
                            const Text(
                              "Select Invoice",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _buildSearchField(
                              title: "Select Invoice",
                              hint: "Select Invoice",
                              value: selectedInvoiceLabel,
                              onTap: _openInvoiceSearch,
                            ),
                          ],
                          if (selectedReceiptType == 'Advance receipt') ...[
                            const Text(
                              "Select Customer",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _buildSearchField(
                              title: "Select Customer",
                              hint: "Select Customer",
                              value: selectedCustomerName,
                              onTap: _openCustomerSearch,
                            ),
                          ],
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
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
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
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
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
                              decoration: InputDecoration(
                                labelText: 'Remark',
                                labelStyle: const TextStyle(fontSize: 12.0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
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
                                      borderSide:
                                          const BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
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
                              controller:
                                  TextEditingController(text: uname.text),
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Name',
                                labelStyle: const TextStyle(fontSize: 12.0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide:
                                      const BorderSide(color: Colors.grey),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
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
                                    if (selectedReceiptType ==
                                        'Order Receipt') {
                                      if (selectedInvoiceId == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            backgroundColor: Colors.red,
                                            content:
                                                Text('Please select invoice'),
                                          ),
                                        );
                                        return;
                                      }
                                      AddReceipt(context);
                                    } else if (selectedReceiptType ==
                                        'Advance receipt') {
                                      if (selectedCustomerId == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            backgroundColor: Colors.red,
                                            content:
                                                Text('Please select customer'),
                                          ),
                                        );
                                        return;
                                      }
                                      AddReceipt2(context);
                                    } else if (selectedReceiptType ==
                                        'other Receipt') {
                                      AddReceipt3(context);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Colors.red,
                                          content: Text(
                                              'Please select receipt type'),
                                        ),
                                      );
                                    }
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
                                    fixedSize: MaterialStateProperty.all<Size>(
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
