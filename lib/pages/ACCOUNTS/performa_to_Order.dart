import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_family.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/order_products.dart';
import 'package:beposoft/pages/ACCOUNTS/view_cart.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/new_grv.dart';
import 'package:beposoft/pages/ACCOUNTS/transfer.dart';

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

class proforma_to_order_request extends StatefulWidget {
 var invoice;
 proforma_to_order_request({super.key,required this.invoice});

  @override
  State<proforma_to_order_request> createState() => _proforma_to_order_requestState();
}

class _proforma_to_order_requestState extends State<proforma_to_order_request> {
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

  List<Map<String, dynamic>> products = [];
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> manager = [];
  String selectmanager = "jeshiya";
  List<String> address = [
    "empty",
  ];
  String selectaddress = "empty";
  List<Map<String, dynamic>> fam = [];
  List<Map<String, dynamic>> customer = [];
  List<Map<String, dynamic>> warehousecusomer1 = [];
  String selectcodtype = "select type";
      List<String> codtype = ["select type","FULL_COD", 'PARTIAL_COD',];
  final TextEditingController codamountcontroller = TextEditingController();
    final TextEditingController advancecodamount = TextEditingController();
  List<Map<String, dynamic>> warehousecusomer2 = [];

  List<Map<String, dynamic>> variant = [];
  int? selectedFamilyId;
  int? selectedCompanyId;
  int? selectedwarehouseId; // Variable to store the selected department's ID
  String? selectedwarehouseName;

  List<Map<String, dynamic>> cartdata = [];
  var Discount;
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> stat = [];

  int? selectedbankId;
  String selectedstaff = '';
  int? selectedstaffId;
  int? selectedstateId;
  int? selectedAddressId; // Variable to store the selected address ID
  String? selectedAddressName; // Variable to store the selected address name
  List<Map<String, dynamic>> bank = [];
  double total = 0.0;
  Set<int> expandedRows = {};
  var famid;
  var staffid;

  @override
  void initState() {
    super.initState();
    initdata();
  }

  var dep;
  void initdata() async {
    dep = await getdepFromPrefs();


    selectedFamilyId = famid;

    selectedstaffId = staffid;
  

    searchController.addListener(() {
    });
    getstate();

    getbank();
    fetchperformalistData();
  }


  
  Future<void> getstate() async {
    try {
      final token = await gettokenFromPrefs();
      var response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        List<Map<String, dynamic>> statelist = productsData
            .map<Map<String, dynamic>>((productData) => {
                  'id': productData['id'],
                  'name': productData['name'],
                })
            .toList();

        setState(() {
          stat = statelist;
        });
      }
    } catch (error) {
      
    }
  }
  String getStateNameById(int stateId) {
    final state = stat.firstWhere(
      (element) => element['id'] == stateId,
      orElse: () => {'name': 'Unknown'}, // Return a Map with a default 'name'
    );
    return state['name'];
  }
  List<Map<String, dynamic>> perfomaItemsWithImages=[];
 Future<void> fetchperformalistData() async {
    try {
      final token = await gettokenFromPrefs();
      final response = await http.get(
        Uri.parse('$api/api/perfoma/${widget.invoice}/invoice/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List<Map<String, dynamic>> performaInvoiceList = [];

       perfomaItemsWithImages =
            (parsed['perfoma_items'] as List<dynamic>?)?.map((item) {
          return {
            'id': item['id'],
            'product':item['product'],
            'name': item['name'],
            'quantity': item['quantity'],
            'actual_price': item['rate'],
            'first_image': item['images'],
            'discount': item['discount'],
          };
        }).toList() ?? [];

        // Get state name from ID
        final stateName = getStateNameById(parsed['state']);

        performaInvoiceList.add({
          'id': parsed['id'],
          'invoice': parsed['invoice'],
          'manage_staff': parsed['manage_staff'],
          'company': parsed['company'],
          'company_name':parsed['company_name'],
          'customer_name': parsed['customer']?['name'] ?? 'Unknown',
          'customerID': parsed['customer']?['id'] ?? 'Unknown',

          'family': parsed['family'],
          'state': parsed['state'], // Use state name instead of ID
          'address': parsed['billing_address']?['address'] ?? 'Unknown',
          'billing_id': parsed['billing_address']['id'],
          'payment_status': parsed['payment_status'],
          'bank': parsed['bank']?['name'] ?? 'Unknown',
          'payment_method': parsed['payment_method'],
          'status': parsed['status'],
          'total_amount': parsed['total_amount'],
          'order_date': parsed['order_date'],
          'created_at': parsed['customer']?['created_at'] ?? 'Unknown',
          'perfoma_items': perfomaItemsWithImages,
          'warehouse_id':parsed['warehouse_id']
        });

        setState(() {
          orders = performaInvoiceList;
        });
        addtocart(perfomaItemsWithImages);
      } else {
        // Handle error response
      }
    } catch (error) {
      // Handle exception
    }
  }
Future<void> addtocart(cartdata) async{
    final token = await gettokenFromPrefs();
 try{
    for (var item in cartdata) {
      

   final response= await http.post(Uri.parse('$api/api/cart/product/'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body:jsonEncode(
    {
     'product':item['product'],
     'quantity':item['quantity'],
    }
  )
  );
      if (response.statusCode == 201) {
      //  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      //     SnackBar(
      //        backgroundColor: Colors.green,
      //       content: Text(' added Successfully.'),
      //     ),
      //   );
        // Navigator.push(context, MaterialPageRoute(builder: (context)=>add_bank()));
      } else {
        // ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        //   SnackBar(
        //     backgroundColor: Colors.red,
        //     content: Text('Adding Bank failed.'),
        //   ),
        // );
      }}

          await fetchCartData();
 }
 catch(e){
  
 }
}

  void ordercreate(
    BuildContext scaffoldContext,
  ) async {
    try {
      final token = await gettokenFromPrefs();
      // warehouse = await getwarehouseFromPrefs();

       String? codStatusToSend;

if (selectcodtype == "select type") {
  codStatusToSend = null;
} else {
  codStatusToSend = selectcodtype;
}
var cod;
if(codamountcontroller.text.trim().isEmpty){
cod=0;
  
}
else{
  cod=codamountcontroller.text;
}

      // Build the base body object
      Map<String, dynamic> requestBody = {
        'manage_staff': orders[0]['manage_staff'],
        'company': orders[0]['company'],
        'customer': orders[0]['customerID'],
        'billing_address': orders[0]['billing_id'],
        'order_date':orders[0]['order_date'],
        'family': orders[0]['family'],
        'state': orders[0]['state'],
        'paymet_status': selectpaystatus,
        'cod_status': codStatusToSend,

        'cod_amount':cod,
        'adv_cod_amount': advancecodamount.text,
        'total_amount': tot,
        'bank': selectedbankId,
        'payment_method': selectpaymethod,
        'status': 'Invoice Created',
      };

      var response = await http.post(
        Uri.parse('$api/api/order/create/'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Order Created Successfully.'),
          ),
        );
        Navigator.push(
          scaffoldContext,
          MaterialPageRoute(builder: (context) => order_products()),
        );
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Adding address failed.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text('Enter valid information'),
        ),
      );
    }
  }

  Future<String?> getwarehouseFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? warehouseId = prefs.getInt('warehouse');

    // Check if warehouseId is null before converting to String
    return warehouseId?.toString();
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

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

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
          String imageUrl = "${productData['image']}";
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



  Future<void> fetchCartData() async {
    try {
      final token = await gettokenFromPrefs();

      final response = await http.get(
        Uri.parse("$api/api/cart/products/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List<dynamic> cartsData = parsed['data'];
        List<Map<String, dynamic>> cartList = [];

        double total = 0.0; // Initialize total here

        for (var cartData in cartsData) {
          // Safely handle the null value for image
          String imageUrl = cartData['image'] ??
              'default_image_url'; // Provide a default value or a placeholder URL

          cartList.add({
            'id': cartData['id'],
            'name': cartData['name'],
            'image': imageUrl,
            'slug': cartData['slug'],
            'size': cartData['size'],
            'quantity': cartData['quantity'],
            'price': cartData['price'],
            'discount': cartData['discount'],
          });
        }

        setState(() {
          cartdata = cartList;

          // Calculate total
          for (var item in cartdata) {
            final discountPerQuantity = item['discount'] ?? 0.0;
            final quantity = int.tryParse(item['quantity'].toString()) ??
                0; // Ensure it's an integer
            final price = double.tryParse(item['price'].toString()) ??
                0.0; // Ensure it's a double
            final totalItemPrice = quantity * price;
            final totalDiscount = quantity * discountPerQuantity;
            total += totalItemPrice - totalDiscount;
          }
        });

        // Call the function to show total in a dialog box
      } else {
        throw Exception('Failed to load cart data');
      }
    } catch (error) {
      // Consider adding error handling in the UI
    }
  }

  var tot;
  void showTotalDialog(BuildContext context) {
    double total = 0.0;
    double totalDiscount = 0.0;
    double totalItemPrice = 0.0;
    // Calculate total
    for (var item in cartdata) {
      final discountPerQuantity = item['discount'] ?? 0.0;
      final quantity = int.tryParse(item['quantity'].toString()) ??
          0; // Ensure it's an integer
      final price = double.tryParse(item['price'].toString()) ??
          0.0; // Ensure it's a double

      totalItemPrice += quantity * price;
      totalDiscount += quantity * discountPerQuantity;

      total = totalItemPrice - totalDiscount;
    }
    setState(() {
      tot = total;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Cart Total"),
          content: SizedBox(
            width: 300, // Set the desired width
            height: 180, // Set the desired height
            child: Column(
              children: [
                Row(
                  children: [
                    Text("Total:"),
                    Spacer(),
                    Text("$totalItemPrice"),
                  ],
                ),
                Divider(),
                Row(
                  children: [
                    Text("Advance paid:"),
                    Spacer(),
                    Text("0.0"),
                  ],
                ),
                Row(
                  children: [
                    Text("Total Discount:"),
                    Spacer(),
                    Text("$totalDiscount"),
                  ],
                ),
                Divider(),
                Row(
                  children: [
                    Text("Shipping Charge:"),
                    Spacer(),
                    Text("0.0"),
                  ],
                ),
                // Row(
                //   children: [
                //     Text("Total Cart Discount:"),
                //     Spacer(),
                //     Text("0.0"),
                //   ],
                // ),

                Divider(),
                Row(
                  children: [
                    Text("Net Amount:"),
                    Spacer(),
                    Text("${total.toStringAsFixed(2)}"),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            SizedBox(
              width: 100,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue, // Set the text color to white
                ),
                onPressed: () {
                  ordercreate(context);
                },
                child: Text("OK"),
              ),
            ),
          ],
        );
      },
    );
  }


  String? selectedValue;
  int? selectedCustomerId;
  final TextEditingController textEditingController = TextEditingController();

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  List<String> paystatus = ["Paid", 'COD', 'credit'];
  List<String> mode = ["request", 'invoice', 'warehouse to warehouse'];

  String selectpaystatus = "Paid";
  String selectedmode = "invoice";

  List<String> paymethod = [
    '1 Razorpay',
    "Credit Card",
    'Debit Card',
    'Net Banking',
    'PayPal',
    'Cash on Delivery (COD)',
    'Bank Transfer'
  ];
  String selectpaymethod = "1 Razorpay";

  void showInvoiceDialog(BuildContext context, double total) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Invoice",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${total?.toStringAsFixed(2) ?? '0.00'}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${total != null ? total.toStringAsFixed(2) : '0.00'}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Discount',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${Discount.toStringAsFixed(2)}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
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
                  ),
                  child: Text("Close", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Custom back arrow
          onPressed: () async {
            Navigator.pop(context);
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
          child: Column(
        children: [
          Container(
            child: Column(
              children: [
                SizedBox(
                  height: 15,
                ),
                Text(
                  "ORDER REQUEST ",
                  style: TextStyle(
                      fontSize: 20,
                      letterSpacing: 9.0,
                      fontWeight: FontWeight.bold),
                ),
                
              ],
            ),
          ),
           Container(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
                    child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                              color: Color.fromARGB(255, 202, 202, 202)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 15,
                              ),
                              Text(
                                "Bank Details ",
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue),
                              ),
                             
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                "Payment Status ",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '',
                                      contentPadding:
                                          EdgeInsets.symmetric(horizontal: 1),
                                    ),
                                    child: DropdownButton<String>(
                                      value: selectpaystatus,
                                      underline:
                                          Container(), // Removes the underline
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectpaystatus = newValue!;
                                        
                                        });
                                      },
                                      items: paystatus
                                          .map<DropdownMenuItem<String>>(
                                              (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(
                                            value,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        );
                                      }).toList(),
                                      icon: Container(
                                        padding: EdgeInsets.only(left: 240),
                                        alignment: Alignment.centerRight,
                                        child: Icon(Icons.arrow_drop_down),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                             if (selectpaystatus == "COD") ...[

                               SizedBox(
                                height: 10,
                              ),
                              Text(
                                "COD Type",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Padding(
  padding: const EdgeInsets.only(right: 10),
  child: Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(10.0),
    ),
    child: InputDecorator(
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 8),
      ),
      child: DropdownButton<String>(
        value: selectcodtype,
        isExpanded: true,                // <-- IMPORTANT (prevents overflow)
        underline: Container(),
        onChanged: (String? newValue) {
          setState(() {
            selectcodtype = newValue!;
          });
        },
        items: codtype.map((value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: TextStyle(fontSize: 12)),
          );
        }).toList(),

        icon: Icon(Icons.arrow_drop_down), // <-- No padding
      ),
    ),
  ),
)
],



                              if (selectpaystatus == "COD") ...[

                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                "COD Amount ",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: TextField(
                                  controller: codamountcontroller,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Enter COD Amount',
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 15),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide:
                                          BorderSide(color: Colors.blue),
                                    ),
                                  ),
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),],
                              
                              if (selectcodtype == "PARTIAL_COD") ...[

                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                "Advance COD Amount ",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: TextField(
                                  controller: advancecodamount,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Enter Advance Amount',
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 15),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide:
                                          BorderSide(color: Colors.blue),
                                    ),
                                  ),
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),],


                              SizedBox(
                                height: 8,
                              ),
                              Text(
                                "Bank",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
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
                                        width: 280,
                                        child: InputDecorator(
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: 'Select',
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 1),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<int>(
                                                hint: Text(
                                                  'Select',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600]),
                                                ),
                                                value: selectedbankId,
                                                isExpanded: true,
                                                dropdownColor:
                                                    const Color.fromARGB(
                                                        255, 255, 255, 255),
                                                icon: Icon(Icons.arrow_drop_down,
                                                    color: const Color.fromARGB(
                                                        255, 107, 107, 107)),
                                                onChanged: (int? newValue) {
                                                  setState(() {
                                                    selectedbankId =
                                                        newValue; // Store the selected family ID
                                                  });
                                                },
                                                items: bank
                                                    .map<DropdownMenuItem<int>>(
                                                        (bank) {
                                                  return DropdownMenuItem<int>(
                                                    value: bank['id'],
                                                    child: Text(
                                                      bank['name'],
                                                      style: TextStyle(
                                                          color: Colors.black87,
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
                              SizedBox(
                                height: 15,
                              ),
                              Text(
                                "Payment Method ",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8), // Adjusted padding
                                    ),
                                    child: DropdownButton<String>(
                                      value: selectpaymethod,
                                      underline:
                                          SizedBox(), // Removes the underline
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectpaymethod = newValue!;
                                        });
                                      },
                                      items: paymethod
                                          .map<DropdownMenuItem<String>>(
                                              (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(
                                            value,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        );
                                      }).toList(),
                                      icon: Icon(Icons
                                          .arrow_drop_down), // Default icon without excessive padding
                                      isExpanded:
                                          true, // Ensures dropdown expands within its container
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(
                                height: 15,
                              ),
                              Text(
                                "ADD Recipt",
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 5,
                              ),





                              SizedBox(
                                height: 8,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
  if (selectpaystatus == "COD") {
    // Validate COD Amount
    if (codamountcontroller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter COD amount"),
          backgroundColor: Colors.red,
        ),
      );
      return; // stop execution, do not show dialog
    }
  }
if (selectpaystatus == "COD" ){
    if (selectcodtype == "Partial_COD") {
      if (advancecodamount.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please enter Advance COD amount"),
            backgroundColor: Colors.red,
          ),
        );
        return; // stop execution, do not show dialog
      }
     
    }
  }
 
  if (selectpaystatus == "COD" ){
    if (selectcodtype == "select type") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select COD type"),
          backgroundColor: Colors.red,
        ),
      );
      return; // stop execution, do not show dialog
    }
  }
 
  // If COD is entered or payment is not COD -> proceed
  showTotalDialog(context);
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
                                        Size(95, 15),
                                      ),
                                    ),
                                    child: Text("Generate Invoice",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                            ],
                          ),
                        )),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
        ],
      )),
    );
  }
}
