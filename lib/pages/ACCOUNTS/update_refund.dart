import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/refund_list.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
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

class updaterefund extends StatefulWidget {
  var id;
  updaterefund({super.key, required this.id});

  @override
  State<updaterefund> createState() => _updaterefundState();
}

class _updaterefundState extends State<updaterefund> {
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

  TextEditingController uname = TextEditingController();
  TextEditingController amount = TextEditingController();
  TextEditingController transactionid = TextEditingController();
  TextEditingController Remark = TextEditingController();
  List<Map<String, dynamic>> bank = [];
  List<Map<String, dynamic>> orders = [];
  DateTime selectedDate = DateTime.now();
  String? selectedInvoiceId; // Variable to store the selected invoice ID
  String? selectedBankId; // Variable to store the selected bank ID
  var respo;
// Add this variable to your _add_receiptState class:
String? selectedReceiptType;
final List<String> receiptTypes = ['Order Refund', 'Advance Refund'];
  Future<String?> gettoken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString('token');
  }

  @override
  void initState() {
    super.initState();
    fetchOrderData();
    getbank();
    getrefund();
    getcustomer();
    // getNameFromJWT(); // Fetch the name from JWT
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
   Future getuserid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  List<Map<String, dynamic>> customer = [];
String? selectedCustomerId;
  Future<void> getcustomer() async {
  try {
    final dep = await getdepFromPrefs();
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

    ;

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      var productsData = parsed['data']; // Directly accessing 'data' since no pagination

      List<Map<String, dynamic>> newCustomers = [];

      for (var productData in productsData) {
        newCustomers.add({
          'id': productData['id'],
          'name': productData['name'],
          'created_at': productData['created_at'],
        });
      }

      // Update UI
      setState(() {
        customer = newCustomers;
        
      });
    } else {
      throw Exception("Failed to load customer data");
    }
  } catch (error) {
    ;
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
        'after_data':  {"Data": "$respo"},
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
  Future<void> fetchOrderData() async {
    try {
      final token = await getTokenFromPrefs();
      final dep = await getdepFromPrefs();
      final jwt = JWT.decode(token!);
      var name = jwt.payload['name'];
      ;

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
        final List ordersData = responseData['results'];

        List<Map<String, dynamic>> newOrders = [];

        for (var orderData in ordersData) {
          newOrders.add({
            'id': orderData['id'],
            'invoice': orderData['invoice'],
            'customer': orderData['customer']['name'],
          });
        }

        setState(() {
          orders = newOrders;
          // filteredOrders = newOrders;
          ;
        });
      } else {
        throw Exception("Failed to load order data");
      }
    } catch (error) {
      ;
    }
  }
  var res;
   Future<void> getrefund() async {
  final token = await gettoken();
   final jwt = JWT.decode(token!);
      var name = jwt.payload['name'];

  try {
    final response = await http.get(
      Uri.parse('$api/api/refund/receipts/${widget.id}/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

  
    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      final data = parsed['data']; // ✅ SINGLE OBJECT

      setState(() {
        // 🔹 Text fields
        res=data;
        amount.text = data['amount'] ?? '';
        transactionid.text = data['transactionID'] ?? '';
        Remark.text = data['note'] ?? '';

        // 🔹 Dropdown selections (convert to String)
        selectedCustomerId = data['customer']?.toString();
        selectedInvoiceId  = data['invoice']?.toString();
        selectedBankId     = data['bank']?.toString();

        // 🔹 Date
        selectedDate = DateTime.parse(data['date']);

        // 🔹 Receipt type logic (optional)
        selectedReceiptType =
            data['invoice'] != null ? 'Order Refund' : 'Advance Refund';
             uname.text=name; 
      });

    }
  } catch (e) {

  }
}

  Future<void> getbank() async {
    final token = await gettoken();
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
    } catch (e) {
      
    }
  }

Future<void> Addrefundlog(BuildContext scaffoldContext, dynamic respo) async {
  final token = await getTokenFromPrefs();

  try {
   

    // 3️⃣ Safe POST request
    final response = await http.post(
      Uri.parse('$api/api/datalog/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'before_data': {
          "status": "Refund updated",
          "refund_no": res['refund_no'],
          "customer_name": res['customer_name'],
          "amount": res['amount'],
          "created_by": res['created_name'],
          "date": res['date'],
          "invoice": res['invoice'],
        },
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

  Future<void> AddRefund(
    BuildContext scaffoldContext,
  ) async {
    final token = await gettoken();
    try {
      final token = await getTokenFromPrefs();
      final jwt = JWT.decode(token!);
      var name = jwt.payload['name'];
      var id = await getuserid();
    

      // Format the selectedDate as a string
      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

      final response = await http.put(
          Uri.parse('$api/api/refund/receipts/${widget.id}/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'transactionID': transactionid.text,
            'customer': selectedCustomerId,
            'invoice': selectedInvoiceId,
            'amount': amount.text,
            'bank': selectedBankId,
            'date': formattedDate, // Use the formatted date string
            'created_by': id,
            'note': Remark.text
          }));

      if (response.statusCode == 200) {
        var Data = jsonDecode(response.body);
        respo = Data['data'];
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Receipt added Successfully.'),
          ),
        );
        await Addrefundlog(scaffoldContext, respo);

        Navigator.push(context, MaterialPageRoute(builder: (context)=>RefundList()));
      } 
      else 
      {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
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

    // Use a post-frame callback to show the SnackBar after the current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ScaffoldMessenger.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged out successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

    // Wait for the SnackBar to disappear before navigating
    await Future.delayed(Duration(seconds: 2));

    // Navigate to the HomePage after the snackbar is shown
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

  // void getNameFromJWT() async {
  //   final token = await getTokenFromPrefs();
  //   if (token != null) {
  //     final jwt = JWT.decode(token);
  //     setState(() {
  //       name = jwt.payload['name']; // Extract and set the name
  //       ;
  //     });
  //   }
  // }
Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
   if(dep=="BDO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => bdo_dashbord()), // Replace AnotherPage with your target page
            );

}
else if(dep=="BDM" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => bdm_dashbord()), // Replace AnotherPage with your target page
            );
}
else if(dep=="warehouse" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WarehouseDashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="CEO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="COO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}


else if(dep=="Warehouse Admin" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WarehouseAdmin()), // Replace AnotherPage with your target page
            );
}else {
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
            "Update Refund",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back), // Custom back arrow
            onPressed: () async {
              final dep = await getdepFromPrefs();
             if(dep=="BDO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => bdo_dashbord()), // Replace AnotherPage with your target page
            );

}
else if(dep=="BDM" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => bdm_dashbord()), // Replace AnotherPage with your target page
            );
}
else if(dep=="warehouse" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WarehouseDashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="CEO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="COO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}


else if(dep=="Warehouse Admin" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WarehouseAdmin()), // Replace AnotherPage with your target page
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
        body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom:55),
              child: Container(
                        child: Column(
              children: [
                SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 10, left: 10),
                  child: Container(
                    width: 600,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 34, 165, 246),
                      border: Border.all(color: Color.fromARGB(255, 202, 202, 202)),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Update Refund",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        SizedBox(
                          height: 13,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 25, left: 15, right: 15),
                  child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        border:
                            Border.all(color: Color.fromARGB(255, 202, 202, 202)),
                      ),
                      width: 700,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 10,
                            ),
                Text(
                      "Refund Type",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: DropdownButton<String>(
              isExpanded: true,
              value: selectedReceiptType,
              hint: Text(
                'Select Refund Type',
                style: TextStyle(fontSize: 12.0),
              ),
               items: receiptTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(
                    type,
                    style: TextStyle(fontSize: 12.0),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedReceiptType = value;
                  if(selectedReceiptType=="Advance Refund"){
                    selectedInvoiceId=null;
                  }
                });
              },
              underline: SizedBox(),
                        ),
                      ),
                    ),
              
                    SizedBox(height: 10),
              
              
                        if(selectedReceiptType =='Order Refund') 
                            Text(
                              "Select Invoice",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            if(selectedReceiptType =='Order Refund') 
                            SizedBox(height: 5),
                            if(selectedReceiptType =='Order Refund')
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedInvoiceId,
                                  hint: Text(
                                    'Select Invoice',
                                    style: TextStyle(fontSize: 12.0),
                                  ),
                                  items: orders.map((order) {
                                    return DropdownMenuItem<String>(
                                      value: order['id'].toString(),
                                      child: Text(
                                        '${order['invoice']} - ${order['customer']}',
                                        style: TextStyle(fontSize: 12.0),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedInvoiceId =
                                          value; // Store the selected invoice ID
                    
                                          
                                    });
                                  },
                                  underline: SizedBox(),
                                ),
                              ),
                            ),
              
                        //  if(selectedReceiptType =='Advance receipt')
                            Text(
                                "Select Customer",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 5),
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: selectedCustomerId,
                                    hint: Text(
                                      'Select Customer',
                                      style: TextStyle(fontSize: 12.0),
                                    ),
              
                items: customer.map((cust) {
                                      return DropdownMenuItem<String>(
                                        value: cust['id'].toString(),
                                        child: Text(
                                          cust['name'],
                                          style: TextStyle(fontSize: 12.0),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedCustomerId = value;
                                      });
                                    },
                                    underline: SizedBox(),
                                  ),
                                ),
                              ),
                            SizedBox(
                              height: 5,
                            ),
                            Text(
                              "Amount",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Container(
                                child: TextField(
                                  controller: amount,
                                  decoration: InputDecoration(
                                    labelText: 'Amount',
                                    labelStyle: TextStyle(
                                      fontSize: 12.0, // Set your desired font size
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              "Transaction Id",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Container(
                                child: TextField(
                                  controller: transactionid,
                                  decoration: InputDecoration(
                                    labelText: 'Transaction Id',
                                    labelStyle: TextStyle(
                                      fontSize: 12.0, // Set your desired font size
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              "Bank",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedBankId,
                                  hint: Text(
                                    'Select Bank',
                                    style: TextStyle(fontSize: 12.0),
                                  ),
                                  items: bank.map((bankItem) {
                                    return DropdownMenuItem<String>(
                                      value: bankItem['id'].toString(),
                                      child: Text(
                                        '${bankItem['name']}',
                                        style: TextStyle(fontSize: 12.0),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedBankId = value; // Store the selected bank ID
                                      ;
                                    });
                                  },
                                  underline: SizedBox(),
                                ),
                              ),
                            ),
                          

                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              "Date",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                           // ...existing code...
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
          labelStyle: TextStyle(fontSize: 12.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 8.0),
        ),
        controller: TextEditingController(
          text: DateFormat('yyyy-MM-dd').format(selectedDate),
        ),
      ),
    ),
  ),
),

                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              "Name",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Container(
                                child: TextField(
                                  controller: TextEditingController(
                                      text: uname.text), // Display the name extracted from JWT
                                  readOnly: true, // Make the field non-editable
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    labelStyle: TextStyle(
                                      fontSize: 12.0, // Set your desired font size
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                              ),
                            ),  SizedBox(height: 10),
                            Text(
                              "Remark",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Padding(
  padding: const EdgeInsets.only(right: 10),
  child: TextField(
    controller: Remark,
    maxLines: 3,        // expands up to 3 lines only
    keyboardType: TextInputType.multiline,
    decoration: InputDecoration(
      labelText: 'Remark',
      labelStyle: const TextStyle(
        fontSize: 12.0,
      ),
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
                            SizedBox(
                              height: 10,
                            ),


                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                  ),
                                  SizedBox(
                                    width: 270,
                                    child: ElevatedButton(
                                      onPressed: () {
                                       AddRefund(context);
                                      },
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                          Color.fromARGB(255, 64, 176, 251),
                                        ),
                                        shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                10), // Set your desired border radius
                                          ),
                                        ),
                                        fixedSize: MaterialStateProperty.all<Size>(
                                          Size(95,
                                              15), // Set your desired width and heigh
                                        ),
                                      ),
                                      child: Text("Submit",
                                          style: TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ]),
                            SizedBox(
                              height: 20,
                            )
                          ],
                        ),
                      )),
                ),
              ],
                        ),
                      ),
            )),
      ),
    );
  }
}
