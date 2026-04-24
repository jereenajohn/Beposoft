import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/advance_receipt_list.dart';
import 'package:beposoft/pages/ACCOUNTS/bankrecipt_list.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/expense_list.dart';
import 'package:beposoft/pages/ACCOUNTS/recipt.report.dart';
import 'package:beposoft/pages/ACCOUNTS/update_department.dart';
import 'package:beposoft/pages/ACCOUNTS/update_family.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:beposoft/main.dart';
import 'package:beposoft/pages/ACCOUNTS/add_credit_note.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/recipts_list.dart';
import 'package:beposoft/pages/ACCOUNTS/add_new_stock.dart';
import 'package:beposoft/pages/ACCOUNTS/credit_note_list.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ACCOUNTS/new_product.dart';
import 'package:beposoft/pages/ACCOUNTS/order_request.dart';
import 'package:beposoft/pages/ACCOUNTS/purchases_request.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:beposoft/pages/ACCOUNTS/add_new_customer.dart';
import 'package:beposoft/pages/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';


class update_advance_recipt extends StatefulWidget {
  final id;
  const update_advance_recipt({super.key,required this.id});

  @override
  State<update_advance_recipt> createState() => _update_advance_reciptState();
}

class _update_advance_reciptState extends State<update_advance_recipt> {
 @override
  void initState() {
    super.initState();
initdata();
fetchOrderData();
    getbank();
  }
void initdata() async {
  getcustomer();
    await getreciptlist();
  }
var url = "$api/api/add/department/";
  List<Map<String, dynamic>> customer = [];

 TextEditingController transactionid = TextEditingController();
  TextEditingController purposes = TextEditingController();
  TextEditingController amount = TextEditingController();
  TextEditingController createdby = TextEditingController();
  TextEditingController remark = TextEditingController();
String? selectedCustomerId;
int? selectedCompanyId;
  TextEditingController name = TextEditingController();
Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
var departments;
  List<Map<String, dynamic>> fam = [];
    List<Map<String, dynamic>> bank = [];
String? selectedpurpose; // Holds the selected value
  final List<String> items = ['water', 'electricity','salary','emi','rent','travel','Others'];
  String? selectedInvoiceId; // Variable to store the selected invoice ID

 String selectedstaff='';
    int? selectedstaffId;
        int? selectedbankId;


          Future<void> getcustomer() async {
  try {
    final dep = await getdepFromPrefs();
    final token = await gettokenFromPrefs();

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

  Future<void> getbank() async{
  final token=await gettokenFromPrefs();
  try{
    final response= await http.get(Uri.parse('$api/api/banks/'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    }
    );
    List<Map<String, dynamic>> banklist = [];
        

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        
        for (var productData in productsData) {
          String imageUrl = "${productData['image']}";
          banklist.add({
            'id': productData['id'],
            'name': productData['name'],
            'branch':productData['branch']
            
          });
        
        }
        setState(() {
          bank = banklist;
                  

          
        });
      }

  }
  catch(e){
    
  }
}
  TextEditingController uname = TextEditingController();

 List<Map<String, dynamic>> orders = [];
Future<void> fetchOrderData() async {
    try {
      final token = await gettokenFromPrefs();
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

      ;
      ;
      ;

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
          uname.text=name;
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

  void getCurrentTime() {
  // Get current date and time
  DateTime now = DateTime.now();

  // Format the time (e.g., HH:mm:ss)
  String formattedTime = DateFormat('HH:mm:ss').format(now);

  
}
  void removeProduct(int index) {
    setState(() {
      fam.removeAt(index);
    });
  }
 String? selectedValue;
  final TextEditingController textEditingController = TextEditingController();

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }
        

 Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
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
       // This prints the formatted date
    });
  }
}
String formatDate(DateTime date) {
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}







Future<void> getreciptlist() async {
  
  try {
    final token = await gettokenFromPrefs();
    var response = await http.get(
      Uri.parse('$api/api/advancereceipt/view/${widget.id}/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
;
setState(() {

    remark.text=parsed['remark']?? '';
     amount.text=parsed['amount']?? '';
      transactionid.text=parsed['transactionID']?? '';
      selectedDate=DateTime.parse(parsed['received_at']);
      selectedbankId=parsed['bank']?? '';
      createdby.text=parsed['created_by_name']?? '';
      selectedCustomerId=parsed['customer'] != null ? parsed['customer'].toString() : null;
  
});
   


    } else {
      
    }
  } catch (error) {
    
  }
}


void updateexpense() async {
  
  final token = await gettokenFromPrefs();

  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username'); 

    
    

    if (username == null) {
      
      return;
    }

    var response = await http.put(
      Uri.parse('$api/api/advancereceipt/view/${widget.id}/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: {
        "customer": selectedCustomerId.toString(),
        "bank": selectedbankId.toString(),
        "amount": amount.text,
        "received_at": formatDate(selectedDate), 
        "transactionID": transactionid.text,
        "remark": remark.text, 
      },
    );

    
    

    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => advance_recipt_Report()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color.fromARGB(255, 49, 212, 4),
          content: Text('Expense Updated successfully'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(


      backgroundColor: Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(
           title: Text(
          "Update Recipt",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Custom back arrow
          onPressed: () async{
                   Navigator.pop(context);
           
          },
        ),

        actions: [
            IconButton(
              icon: Image.asset('lib/assets/profile.png'),
               
              onPressed: () {
                
              },
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
  padding: EdgeInsets.symmetric(horizontal: 1),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10.0),
      border: Border.all(color: Color.fromARGB(255, 202, 202, 202)),
    ),
    width: constraints.maxWidth * 0.9,
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: constraints.maxWidth * 0.9,
            decoration: BoxDecoration(
              color:const Color.fromARGB(255, 2, 65, 96),
              border: Border.all(color: Color.fromARGB(255, 202, 202, 202)),
            ),
            child: Column(
              children: [
                SizedBox(height: 10),
                Text(
                  "Update Recipt",
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

          //  Text(
          //                   "Select Invoice",
          //                   style: TextStyle(
          //                       fontSize: 12, fontWeight: FontWeight.bold),
          //                 ),
          //                 SizedBox(height: 5),
          //                 Padding(
          //                   padding: const EdgeInsets.only(right: 10),
          //                   child: Container(
          //                     padding: EdgeInsets.symmetric(horizontal: 10),
          //                     decoration: BoxDecoration(
          //                       border: Border.all(color: Colors.grey),
          //                       borderRadius: BorderRadius.circular(10.0),
          //                     ),
          //                     child: DropdownButton<String>(
          //                       isExpanded: true,
          //                       value: selectedInvoiceId,
          //                       hint: Text(
          //                         'Select Invoice',
          //                         style: TextStyle(fontSize: 12.0),
          //                       ),
          //                       items: orders.map((order) {
          //                         return DropdownMenuItem<String>(
          //                           value: order['id'].toString(),
          //                           child: Text(
          //                             '${order['invoice']} - ${order['customer']}',
          //                             style: TextStyle(fontSize: 12.0),
          //                           ),
          //                         );
          //                       }).toList(),
          //                       onChanged: (value) {
          //                         setState(() {
          //                           selectedInvoiceId =
          //                               value; // Store the selected invoice ID
      
          //                               ;
          //                         });
          //                       },
          //                       underline: SizedBox(),
          //                     ),
          //                   ),
          //                 ),

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
              
                items: [
  DropdownMenuItem<String>(
    value: null,
    child: Text('No Customer'),
  ),
  ...customer.map((cust) {
    return DropdownMenuItem<String>(
      value: cust['id'].toString(),
      child: Text(cust['name']),
    );
  }).toList(),
],
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
              fontSize: 15,
            ),
          ),
          SizedBox(height: 5),
          Container(
            child: TextField(
              controller: amount,
              
              decoration: InputDecoration(
                labelText: 'Amount',
                                hintText: amount.text.isNotEmpty ? amount.text : 'Enter your amount',

                labelStyle: TextStyle(
        fontSize: 13.0, // Adjust the font size as needed
      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 8.0),
              ),
            ),
          ),
                    SizedBox(height: 5),




          SizedBox(height: 5,),
          
            Text(
                      "Payment Date",
                      style: TextStyle(
                          fontSize: 13, ),
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
                                    color:
                                        Color.fromARGB(255, 116, 116, 116)),
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
                      "Created By",
                      style: TextStyle(
                          fontSize: 13, ),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Container(
  child: TextField(
    controller: createdby,
    readOnly: true, // Makes the TextField non-editable
    decoration: InputDecoration(
      labelStyle: TextStyle(
        fontSize: 13.0, // Adjust the font size as needed
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.grey),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 8.0),
    ),
  ),
),


                       SizedBox(height: 5,),
                     Text("Bank",style: TextStyle(fontSize: 12),),
                      SizedBox(height: 5,),
              
Padding(
  padding: const EdgeInsets.only(right: 10),
  child: Container(
    height: 49,
    decoration: BoxDecoration(
      border: Border.all(color: const Color.fromARGB(255, 206, 206, 206)),
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
              hintText: 'Select Bank',
              contentPadding: EdgeInsets.symmetric(horizontal: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                hint: Text(
                  'Select Bank',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                value: selectedbankId, // Selected bank ID
                isExpanded: true,
                dropdownColor: const Color.fromARGB(255, 255, 255, 255),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: const Color.fromARGB(255, 107, 107, 107),
                ),
                onChanged: (int? newValue) {
                  setState(() {
                    selectedbankId = newValue; // Update the selected bank ID
                    
                  });
                },
                items: bank.map<DropdownMenuItem<int>>((bankItem) {
                  return DropdownMenuItem<int>(
                    value: bankItem['id'], // Use the bank's `id`
                    child: Text(
                      bankItem['name'], // Display the bank's `name`
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
),

   Text(
            "Transaction ID",
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
        fontSize: 13.0, // Adjust the font size as needed
      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 8.0),
              ),
            ),
          ),
                    SizedBox(height: 5),

          Text(
            "Remark",
            style: TextStyle(
              fontSize: 13,
            ),
          ),
          SizedBox(height: 5),
          Container(
            child: TextField(
              controller: remark,
              decoration: InputDecoration(
                labelText: 'remark',
                labelStyle: TextStyle(
        fontSize: 13.0, // Adjust the font size as needed
      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 8.0),
              ),
            ),
          ),
          SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {
              setState(() {

                updateexpense();

              });
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                Colors.blue,
              ),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              fixedSize: MaterialStateProperty.all<Size>(
                Size(constraints.maxWidth * 0.4, 50),
              ),
            ),
            child: Text("Submit", style: TextStyle(color: Colors.white)),
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
)
    );
  }

}