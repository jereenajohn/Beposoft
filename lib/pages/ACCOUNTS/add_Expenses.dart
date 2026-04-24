import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:beposoft/pages/api.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_button2/dropdown_button2.dart';

import 'package:shared_preferences/shared_preferences.dart';

class add_expence extends StatefulWidget {
  const add_expence({super.key});

  @override
  State<add_expence> createState() => _add_expenceState();
}

class _add_expenceState extends State<add_expence> {
  bool showAddNewField = false; // State variable to manage visibility
  TextEditingController newPurposeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getcompany();
    getstaff();
    getbank();
    getemi();
    getcategory();
    getpurpose();
  }

  var url = "$api/api/add/department/";
  TextEditingController transactionid = TextEditingController();
  TextEditingController purposes = TextEditingController();
  TextEditingController amount = TextEditingController();
  TextEditingController description = TextEditingController();
  TextEditingController proname = TextEditingController();
  TextEditingController quantity = TextEditingController();
  int? selectedCompanyId;
  int? selectedCategoryId;

  String? selectedPurposeName;
  int? selectedPurposeId;
  TextEditingController name = TextEditingController();
  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  List<Map<String, dynamic>> purposesofpay = [];

  Map<String, dynamic>? emiData;

  var departments;
  List<Map<String, dynamic>> fam = [];
  List<Map<String, dynamic>> bank = [];
  String? selectedpurpose;
  List<Map<String, dynamic>> emiPayments = [];
  bool isLoading = true;
  String? errorMessage;

  String? selectedtype = 'expenses';

    String? selectedtype1='miscellaneous';


  final List<String> items = [
    'water',
    'electricity',
    'salary',
    'emi',
    'rent',
    'travel',
    'Other assets',
    'Others'
  ];
  final List<String> exp = ['assets', 'expenses'];
  final List<String> expensecategory = ['miscellaneous','permanent','emi','cargo','purchase', 'Other'];

Future<void> AddStatusTime(BuildContext scaffoldContext) async {
  final token = await gettokenFromPrefs();
  try {
    final response = await http.post(
      Uri.parse('$api/api/datalog/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
         'before_data': {"Action": "Expense added "},
        'after_data':  {"Data": "$responseData"},
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

  List<Map<String, dynamic>> category = [];
  Future<void> getEmiReport(var id) async {
    final token = await gettokenFromPrefs();

    ;
    try {
      final response = await http.get(
        Uri.parse('$api/apis/emiexpense/$id/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      ;
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        setState(() {
          emiData = {
            'emi_name': parsed['emi_name'],
            'principal': parsed['principal'],
            'tenure_months': parsed['tenure_months'],
            'annual_interest_rate': parsed['annual_interest_rate'],
            'down_payment': parsed['down_payment'],
            'total_amount_paid': parsed['total_amount_paid'],
            'emi_amount': parsed['emi_amount'],
            'total_interest': parsed['total_interest'],
            'total_payment': parsed['total_payment'],
            'startdate': parsed['startdate'],
            'enddate': parsed['enddate'],
          };

          List<Map<String, dynamic>> payments =
              List<Map<String, dynamic>>.from(parsed['emidata']);
          // Process missing months
          emiPayments = fillMissingMonths(payments);

          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> fillMissingMonths(
      List<Map<String, dynamic>> payments) {
    if (payments.isEmpty) return [];

    List<Map<String, dynamic>> filledPayments = [];
    payments.sort((a, b) => a['date'].compareTo(b['date'])); // Sort by date

    DateTime startDate = DateTime.parse(payments.first['date']);
    DateTime endDate = DateTime.parse(payments.last['date']);

    // Ensure the set is explicitly of type Set<String>
    Set<String> existingMonths =
        payments.map<String>((p) => p['date'].substring(0, 7)).toSet();
    Map<String, Map<String, dynamic>> paymentMap = {
      for (var payment in payments) payment['date']: payment
    };

    DateTime currentDate = DateTime(startDate.year, startDate.month, 1);

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      String monthKey =
          "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}";

      // If there's an exact date payment in this month, add it
      bool found = false;
      for (var payment in payments) {
        if (payment['date'].startsWith(monthKey)) {
          filledPayments.add(payment);
          found = true;
        }
      }

      // If the month is missing, add a "Pending" entry
      if (!found) {
        filledPayments.add({
          'date': monthKey, // Only Year-Month for missing months
          'amount': 0.0,
        });
      }

      currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
    }

    return filledPayments;
  }

  void addpurpose(BuildContext context) async {
    final token = await gettokenFromPrefs();

    try {
      var response = await http.post(
        Uri.parse('$api/apis/add/purpose/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {
          "name": newPurposeController.text,
        },
      );

      ;

      if (response.statusCode == 201) {
        getpurpose();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color.fromARGB(255, 49, 212, 4),
            content: Text('sucess'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('An error occurred. Please try again.'),
        ),
      );
    }
  }

  Future<void> getpurpose() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/apis/add/purpose/'),
        headers: {
          'Authorization': ' Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> purposelist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        for (var productData in parsed) {
          if (productData['name'] != null) {
            // Filter out null names
            purposelist.add({
              'id': productData['id'],
              'name': productData['name'],
            });
          }
        }
        setState(() {
          purposesofpay = purposelist;
        });
      }
    } catch (error) {}
  }

  Future<void> getcategory() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/apis/add/assetcategory/'),
        headers: {
          'Authorization': ' Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      ;
      List<Map<String, dynamic>> categorylist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        for (var productData in parsed) {
          if (productData['category_name'] != null &&
              productData['category_name'] != '') {
            categorylist.add({
              'id': productData['id'],
              'name': productData['category_name'],
            });
          }
          setState(() {
            category = categorylist;
            ;
          });
        }
      }
    } catch (error) {}
  }

  String? selectedEmiName;
  int? selectedEmiId;
  TextEditingController textEditingController = TextEditingController();
  List<Map<String, dynamic>> emiList = [];

  Future<void> getemi() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/apis/emi/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> emiDataList = [];
      ;
      ;
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          emiDataList.add({
            'id': productData['id'],
            'emi_name': productData['emi_name'],
            'emi': productData['emi'],
            'principal': productData['principal'],
            'annual_interest_rate': productData['annual_interest_rate'],
            'tenure_months': productData['tenure_months'],
            'down_payment': productData['down_payment'],
          });
        }
        setState(() {
          emiList = emiDataList;
          ;
        });
      }
    } catch (error) {
      // Handle error
    }
  }

  String selectedstaff = '';
  int? selectedstaffId;
  int? selectedbankId;
  Future<void> getbank() async {
    final token = await gettokenFromPrefs();
    try {
      final response = await http.get(Uri.parse('$api/api/banks/'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
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
    } catch (e) {}
  }

  List<Map<String, dynamic>> sta = [];

  Future<void> getstaff() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/staffs/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> stafflist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          stafflist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }
        setState(() {
          sta = stafflist;
        });
      }
    } catch (error) {}
  }

  void getCurrentTime() {
    // Get current date and time
    DateTime now = DateTime.now();

    // Format the time (e.g., HH:mm:ss)
    String formattedTime = DateFormat('HH:mm:ss').format(now);
  }

  Future<void> deletefamily(int Id) async {
    final token = await gettokenFromPrefs();

    try {
      final response = await http.delete(
        Uri.parse('$api/api/family/update/$Id/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color.fromARGB(255, 49, 212, 4),
            content: Text('Deleted sucessfully'),
          ),
        );
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => add_expence()));
      }

      if (response.statusCode == 204) {
      } else {
        throw Exception('Failed to delete wishlist ID: $Id');
      }
    } catch (error) {}
  }

  void removeProduct(int index) {
    setState(() {
      fam.removeAt(index);
    });
  }

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
            d.navigateToSelectedPage(
                context, option); // Navigate to selected page
          },
        );
      }).toList(),
    );
  }

  //searchable dropdown

  String? selectedValue;

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  List<Map<String, dynamic>> company = [];

  Future<void> getcompany() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/company/data/'),
        headers: {
          'Authorization': ' Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> companylist = [];

      if (response.statusCode == 200) {
        final Data = jsonDecode(response.body);
        final productsData = Data['data'];

        for (var productData in productsData) {
          companylist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }
        setState(() {
          company = companylist;
        });
      }
    } catch (error) {}
  }

  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
var responseData;
  void addexpense() async {
    final token = await gettokenFromPrefs();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null) {
        return;
      }

      // Parse the amount from the TextEditingController
      double enteredAmount = double.tryParse(amount.text) ?? 0.0;

      // Check if emiData exists and validate the total amount
      if (emiData != null) {
        double totalAmountPaid = emiData!['total_amount_paid'] ?? 0.0;
        double totalPayment = emiData!['total_payment'] ?? 0.0;

        if ((totalAmountPaid + enteredAmount) > totalPayment) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text('Error: Total amount exceeds the allowed payment.'),
            ),
          );
          return; // Stop further execution
        }
      }

      var response = await http.post(
        Uri.parse('$api/api/expense/add/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {
          "company": selectedCompanyId.toString(),
          "payed_by": selectedstaffId.toString(),
          "bank": selectedbankId.toString(),
          "purpose_of_payment": selectedPurposeId.toString(),
          "amount": amount.text,
          'loan': selectedEmiId.toString(),
          "expense_date": formatDate(selectedDate),
          "transaction_id": transactionid.text,
          "description": description.text,
          "added_by": username,
          "asset_types": selectedtype,
          "name": proname.text,
          "quantity": quantity.text,
          "expense_type": selectedtype1
        },
      );

      if (response.statusCode == 200) {
       var Data = jsonDecode(response.body);
        responseData = Data['data'];
        AddStatusTime(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_expence()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color.fromARGB(255, 49, 212, 4),
            content: Text('Expense added successfully'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to add expense. Please try again.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('An error occurred. Please try again.'),
        ),
      );
    }
  }

  void addexpensetwo() async {
    final token = await gettokenFromPrefs();
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null) {
        return;
      }
      var response = await http.post(
        Uri.parse('$api/api/expense/addexpectemi/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {
          "company": selectedCompanyId.toString(),
          "payed_by": selectedstaffId.toString(),
          "bank": selectedbankId.toString(),
          "purpose_of_payment": selectedPurposeId.toString(),
          "amount": amount.text,
          // 'loan': selectedEmiId.toString(),
          // 'category': selectedCategoryId.toString(),
          "expense_date": formatDate(selectedDate),
          "transaction_id": transactionid.text,
          "description": description.text,
          "added_by": username,
          "asset_types": selectedtype,
          "expense_type":selectedtype1
          // "name": proname.text,
          // "quantity": quantity.text,
        },
      );
      if (response.statusCode == 200) {
        var Data = jsonDecode(response.body);
        responseData = Data['data'];
        AddStatusTime(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_expence()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color.fromARGB(255, 49, 212, 4),
            content: Text('Expense added successfully'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to add expense. Please try again.'),
          ),
        );
      }
    } catch (e) {
      ;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('An error occurred. Please try again.'),
        ),
      );
    }
  }

  void addexpensethree() async {
    final token = await gettokenFromPrefs();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null) {
        return;
      }
      var response = await http.post(
        Uri.parse('$api/api/assest/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {
          "company": selectedCompanyId.toString(),
          "payed_by": selectedstaffId.toString(),
          "bank": selectedbankId.toString(),
          "purpose_of_payment": selectedPurposeId.toString(),
          "amount": amount.text,
          // 'loan': selectedEmiId.toString(),
          'category': selectedCategoryId.toString(),
          "expense_date": formatDate(selectedDate),
          "transaction_id": transactionid.text,
          "description": description.text,
          "added_by": username,
          "asset_types": selectedtype,
          "name": proname.text,
          "quantity": quantity.text,
          "expense_type": selectedtype1
        },
      );

      ;

      if (response.statusCode == 200) {
         var Data = jsonDecode(response.body);
        responseData = Data['data'];
        AddStatusTime(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_expence()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color.fromARGB(255, 49, 212, 4),
            content: Text('Expense added successfully'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to add expense. Please try again.'),
          ),
        );
      }
    } catch (e) {
      ;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('An error occurred. Please try again.'),
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent the swipe-back gesture (and back button)
        _navigateBack();
        return false;
      },
      child: Scaffold(
          backgroundColor: Color.fromARGB(242, 255, 255, 255),
          appBar: AppBar(
            title: Text(
              "Add Expense",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back), // Custom back arrow
              onPressed: () async {
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
                } else if (dep == "Warehouse Admin") {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            WarehouseAdmin()), // Replace AnotherPage with your target page
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
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            dashboard()), // Replace AnotherPage with your target page
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  child: Column(
                    children: [
                      SizedBox(height: 15),
                      Padding(
                        padding: EdgeInsets.only(bottom: 55),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                                color: Color.fromARGB(255, 202, 202, 202)),
                          ),
                          width: constraints.maxWidth * 0.9,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: 10, left: 10, right: 10, bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: constraints.maxWidth * 0.9,
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 2, 65, 96),
                                    border: Border.all(
                                        color:
                                            Color.fromARGB(255, 202, 202, 202)),
                                  ),
                                  child: Column(
                                    children: [
                                      SizedBox(height: 10),
                                      Text(
                                        "New Expence",
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

                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey, width: 1.0),
                                          borderRadius: BorderRadius.circular(
                                              8.0), // Rounded corners
                                        ),
                                        child: DropdownButton<int>(
                                          isExpanded: true,
                                          underline:
                                              SizedBox(), // Removes default underline
                                          hint: Text(
                                            'Select a company',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600]),
                                          ),
                                          value: selectedCompanyId,
                                          items: company.map((item) {
                                            return DropdownMenuItem<int>(
                                              value: item['id'],
                                              child: Text(item['name']),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              selectedCompanyId = value;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Text(
                                  "Amount",
                                  style: TextStyle(
                                    fontSize: 15,
                                  ),
                                ),

                                SizedBox(height: 5),
                                Container(
                                  child: TextField(
                                    controller: amount,
                                    decoration: InputDecoration(
                                      labelText: 'Amount',
                                      labelStyle: TextStyle(
                                        fontSize:
                                            13.0, // Adjust the font size as needed
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        borderSide:
                                            BorderSide(color: Colors.grey),
                                      ),
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 8.0),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "Select Type",
                                  style: TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: .0),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey, width: 1.0),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: DropdownButton<String>(
                                    value: exp.contains(selectedtype)
                                        ? selectedtype
                                        : null,
                                    hint: Text('Select an option'),
                                    isExpanded: true,
                                    underline: SizedBox(),
                                    items: exp.map((String item) {
                                      return DropdownMenuItem<String>(
                                        value: item,
                                        child: Text(item),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          selectedtype = newValue;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(
                                  height: 5,
                                ),


                                  Text(
                                  "Select Expense Category",
                                  style: TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: .0),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey, width: 1.0),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: DropdownButton<String>(
                                    value: expensecategory.contains(selectedtype1)
                                        ? selectedtype1
                                        : null,
                                    hint: Text('Select an option'),
                                    isExpanded: true,
                                    underline: SizedBox(),
                                    items: expensecategory.map((String item) {
                                      return DropdownMenuItem<String>(
                                        value: item,
                                        child: Text(item),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue1) {
                                      if (newValue1 != null) {
                                        setState(() {
                                          selectedtype1 = newValue1;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(
                                  height: 5,
                                ),


                                if (selectedtype == 'assets')
                                  Text(
                                    "Product name",
                                    style: TextStyle(
                                      fontSize: 15,
                                    ),
                                  ),
                                if (selectedtype == 'assets')
                                  SizedBox(height: 5),
                                if (selectedtype == 'assets')
                                  Container(
                                    child: TextField(
                                      controller: proname,
                                      decoration: InputDecoration(
                                        labelText: 'Product Name',
                                        labelStyle: TextStyle(
                                          fontSize:
                                              13.0, // Adjust the font size as needed
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          borderSide:
                                              BorderSide(color: Colors.grey),
                                        ),
                                        contentPadding:
                                            EdgeInsets.symmetric(vertical: 8.0),
                                      ),
                                    ),
                                  ),

                                if (selectedtype == 'assets')
                                  SizedBox(height: 5),
                                if (selectedtype == 'assets')
                                  Text(
                                    "category",
                                    style: TextStyle(
                                      fontSize: 15,
                                    ),
                                  ),
                                if (selectedtype == 'assets')
                                  SizedBox(height: 5),
                                if (selectedtype == 'assets')
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10.0),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey, width: 1.0),
                                            borderRadius: BorderRadius.circular(
                                                8.0), // Rounded corners
                                          ),
                                          child: DropdownButton<int>(
                                            isExpanded: true,
                                            underline:
                                                SizedBox(), // Removes default underline
                                            hint: Text(
                                              'Select a category',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600]),
                                            ),
                                            value: selectedCategoryId,
                                            items: category.map((item) {
                                              return DropdownMenuItem<int>(
                                                value: item['id'],
                                                child: Text(item['name']),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                selectedCategoryId = value;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                if (selectedtype == 'assets')
                                  SizedBox(height: 5),

                                if (selectedtype == 'assets')
                                  Text(
                                    "Quantity",
                                    style: TextStyle(
                                      fontSize: 15,
                                    ),
                                  ),
                                if (selectedtype == 'assets')
                                  SizedBox(height: 5),
                                if (selectedtype == 'assets')
                                  Container(
                                    child: TextField(
                                      controller: quantity,
                                      decoration: InputDecoration(
                                        labelText: 'Quantity',
                                        labelStyle: TextStyle(
                                          fontSize:
                                              13.0, // Adjust the font size as needed
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          borderSide:
                                              BorderSide(color: Colors.grey),
                                        ),
                                        contentPadding:
                                            EdgeInsets.symmetric(vertical: 8.0),
                                      ),
                                    ),
                                  ),
                                SizedBox(
                                  height: 10,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Purpose Of Payment",
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    SizedBox(height: 5),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12.0),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey, width: 1.0),
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: DropdownButton<String>(
                                              value: purposesofpay.any((item) =>
                                                      item['name'] ==
                                                      selectedPurposeName)
                                                  ? selectedPurposeName
                                                  : null,
                                              hint: Text('Select an option'),
                                              isExpanded: true,
                                              underline: SizedBox(),
                                              items: purposesofpay.map(
                                                  (Map<String, dynamic> item) {
                                                return DropdownMenuItem<String>(
                                                  value: item['name'],
                                                  child: Text(item['name']),
                                                );
                                              }).toList(),
                                              onChanged: (String? newValue) {
                                                if (newValue != null &&
                                                    newValue != 'add_new') {
                                                  setState(() {
                                                    selectedPurposeName =
                                                        newValue;
                                                    selectedPurposeId =
                                                        purposesofpay
                                                            .firstWhere((item) =>
                                                                item['name'] ==
                                                                newValue)['id'];
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                showAddNewField =
                                                    !showAddNewField;
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors
                                                  .blue, // Background color
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        10.0), // Border radius
                                              ),
                                            ),
                                            child: Text('Add New',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (showAddNewField) ...[
                                      SizedBox(height: 10),
                                      TextField(
                                        controller: newPurposeController,
                                        decoration: InputDecoration(
                                          labelText: 'New Purpose',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      ElevatedButton(
                                        onPressed: () {
                                          // Handle adding new purpose
                                          addpurpose(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.green, // Background color
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                10.0), // Border radius
                                          ),
                                        ),
                                        child: Text('Add',
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ],
                                ),
                                if (selectedPurposeName == 'emi')
                                  SizedBox(
                                    height: 5,
                                  ),
                                if (selectedPurposeName == 'emi')
                                  Text(
                                    "EMI Plan",
                                    style: TextStyle(
                                      fontSize: 13,
                                    ),
                                  ),
                                SizedBox(
                                  height: 5,
                                ),

                                if (selectedPurposeName == 'emi')
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return Container(
                                          child: DropdownButtonHideUnderline(
                                            child: Container(
                                              height: 46,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.grey,
                                                    width: 1.0),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              child: DropdownButton2<String>(
                                                isExpanded: true,
                                                hint: Text(
                                                  'Select an EMI Plan',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context)
                                                          .hintColor),
                                                ),
                                                items: emiList
                                                    .map((emi) =>
                                                        DropdownMenuItem<
                                                            String>(
                                                          value:
                                                              emi['emi_name'],
                                                          child: Text(
                                                            emi['emi_name'],
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        12),
                                                          ),
                                                        ))
                                                    .toList(),
                                                value: selectedEmiName,
                                                onChanged: (value) {
                                                  setState(() {
                                                    selectedEmiName = value;
                                                    selectedEmiId = emiList
                                                        .firstWhere((emi) =>
                                                            emi['emi_name'] ==
                                                            value)['id'];
                                                    getEmiReport(selectedEmiId);
                                                  });

                                                  // Call a function to process selected EMI if needed
                                                },
                                                buttonStyleData:
                                                    const ButtonStyleData(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 16),
                                                  height: 40,
                                                ),
                                                dropdownStyleData:
                                                    const DropdownStyleData(
                                                  maxHeight: 200,
                                                ),
                                                menuItemStyleData:
                                                    const MenuItemStyleData(
                                                  height: 40,
                                                ),
                                                dropdownSearchData:
                                                    DropdownSearchData(
                                                  searchController:
                                                      textEditingController,
                                                  searchInnerWidgetHeight: 50,
                                                  searchInnerWidget: Container(
                                                    height: 50,
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 8,
                                                            bottom: 4,
                                                            right: 8,
                                                            left: 8),
                                                    child: TextFormField(
                                                      expands: true,
                                                      maxLines: null,
                                                      controller:
                                                          textEditingController,
                                                      decoration:
                                                          InputDecoration(
                                                        isDense: true,
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 10,
                                                                vertical: 8),
                                                        hintText:
                                                            'Search EMI Plan...',
                                                        hintStyle:
                                                            const TextStyle(
                                                                fontSize: 12),
                                                        border:
                                                            OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8)),
                                                      ),
                                                    ),
                                                  ),
                                                  searchMatchFn:
                                                      (item, searchValue) {
                                                    return item.value
                                                        .toString()
                                                        .toLowerCase()
                                                        .contains(searchValue
                                                            .toLowerCase());
                                                  },
                                                ),
                                                onMenuStateChange: (isOpen) {
                                                  if (!isOpen) {
                                                    textEditingController
                                                        .clear();
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                Text(
                                  "Payment Date",
                                  style: TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      width: 350, // Set the desired width here
                                      height: 46, // Set the desired height here
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors
                                              .grey, // You can set the border color here
                                          width:
                                              1.0, // You can adjust the border width here
                                        ),
                                        borderRadius: BorderRadius.circular(
                                            8.0), // You can adjust the border radius here
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 30,
                                          ),
                                          Text(
                                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                            style: TextStyle(
                                                fontSize: 15,
                                                color: Color.fromARGB(
                                                    255, 116, 116, 116)),
                                          ),
                                          SizedBox(
                                            width: 162,
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              _selectDate(context);
                                            },
                                            child: Icon(Icons.date_range),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  "Paid By",
                                  style: TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(
                                  height: 5,
                                ),

                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Container(
                                    height: 49,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(width: 20),
                                        Container(
                                          width: 270,
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: '',
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 1),
                                            ),
                                            child: DropdownButton<int>(
                                              value: selectedstaffId,
                                              isExpanded: true,
                                              underline:
                                                  Container(), // This removes the underline
                                              hint: Text(
                                                'Select a Paid by',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600]),
                                              ),
                                              onChanged: (int? newValue) {
                                                setState(() {
                                                  selectedstaffId = newValue!;
                                                });
                                              },
                                              items: sta
                                                  .map<DropdownMenuItem<int>>(
                                                      (staff) {
                                                return DropdownMenuItem<int>(
                                                  value: staff['id'],
                                                  child: Text(
                                                    staff['name'],
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                );
                                              }).toList(),
                                              icon: Container(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Icon(Icons
                                                    .arrow_drop_down), // Dropdown arrow icon
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  "Bank",
                                  style: TextStyle(fontSize: 12),
                                ),
                                SizedBox(
                                  height: 5,
                                ),

                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Container(
                                    height: 49,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: const Color.fromARGB(
                                              255, 206, 206, 206)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(width: 20),
                                        Container(
                                          width: 270,
                                          child: InputDecorator(
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                hintText: 'Select',
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 1),
                                              ),
                                              child:
                                                  DropdownButtonHideUnderline(
                                                child: DropdownButton<int>(
                                                  hint: Text(
                                                    'Select Bank',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors.grey[600]),
                                                  ),
                                                  value: selectedbankId,
                                                  isExpanded: true,
                                                  dropdownColor:
                                                      const Color.fromARGB(
                                                          255, 255, 255, 255),
                                                  icon: Icon(
                                                      Icons.arrow_drop_down,
                                                      color:
                                                          const Color.fromARGB(
                                                              255,
                                                              107,
                                                              107,
                                                              107)),
                                                  onChanged: (int? newValue) {
                                                    setState(() {
                                                      selectedbankId =
                                                          newValue; // Store the selected family ID
                                                    });
                                                  },
                                                  items: bank.map<
                                                      DropdownMenuItem<
                                                          int>>((bank) {
                                                    return DropdownMenuItem<
                                                        int>(
                                                      value: bank['id'],
                                                      child: Text(
                                                        bank['name'],
                                                        style: TextStyle(
                                                            color:
                                                                Colors.black87,
                                                            fontSize: 12),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              )),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                Text(
                                  "Transaction Id",
                                  style: TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Container(
                                  child: TextField(
                                    controller: transactionid,
                                    decoration: InputDecoration(
                                      labelText: 'No.',
                                      labelStyle: TextStyle(
                                        fontSize:
                                            13.0, // Adjust the font size as needed
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        borderSide:
                                            BorderSide(color: Colors.grey),
                                      ),
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 8.0),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 5),

                                Text(
                                  "Description",
                                  style: TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Container(
                                  child: TextField(
                                    controller: description,
                                    decoration: InputDecoration(
                                      labelText: 'Description',
                                      labelStyle: TextStyle(
                                        fontSize:
                                            13.0, // Adjust the font size as needed
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        borderSide:
                                            BorderSide(color: Colors.grey),
                                      ),
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 8.0),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 15),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      if (selectedtype == 'expenses') {
                                        if (selectedPurposeName == 'emi') {
                                          addexpense();
                                        } else {
                                          addexpensetwo();
                                        }
                                      } else {
                                        addexpensethree();
                                      }
                                    });
                                  },
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      Colors.blue,
                                    ),
                                    shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    fixedSize: MaterialStateProperty.all<Size>(
                                      Size(constraints.maxWidth * 0.4, 50),
                                    ),
                                  ),
                                  child: Text("Submit",
                                      style: TextStyle(color: Colors.white)),
                                ),

                                // Displaying the list of departments as a table
                                SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                    ],
                  ),
                ),
              );
            },
          )),
    );
  }
}
