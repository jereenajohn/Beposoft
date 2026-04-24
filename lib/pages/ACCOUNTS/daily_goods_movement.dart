import 'dart:convert';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dgm.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/profilepage.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class daily_goods_movement extends StatefulWidget {
  @override
  _daily_goods_movementState createState() => _daily_goods_movementState();
}

class _daily_goods_movementState extends State<daily_goods_movement> {
  List<Map<String, dynamic>> goods = [];
  List<Map<String, dynamic>> filteredOrders = [];

  DateTime? selectedDate; // For single date filter
  DateTime? startDate; // For date range filter
  DateTime? endDate; // For date range filter
// //dateselection
//    DateTime selectedDate = DateTime.now();
     

//   Future<void> _selectDate(BuildContext context) async {
//        
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//         
//       });
//     }
//   }

  Future<void> getgoodsdetails() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/warehouse/box/detail/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> goodsList = [];
      if (response.statusCode == 200) {
        final productsData = jsonDecode(response.body);

        for (var productData in productsData) {
          var totweight= productData['total_weight']/1000;

          goodsList.add({
            'shipped_date': productData['shipped_date'],
            'total_weight': totweight.toStringAsFixed(2),
            'total_boxes': productData['total_boxes'],
            'total_volume_weight': productData['total_volume_weight'],
            'total_shipping_charge': productData['total_shipping_charge'],
          });
        }

        setState(() {
          goods = goodsList;
          filteredOrders=goods;
        });
      }
    } catch (error) {
      
    }
  }


   Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
   drower d=drower();
   Widget _buildDropdownTile(BuildContext context, String title, List<String> options) {
    return ExpansionTile(
      title: Text(title),
      children: options.map((option) {
        return ListTile(
          title: Text(option),
          onTap: () {
            Navigator.pop(context);
            d.navigateToSelectedPage(context, option); // Navigate to selected page
          },
        );
      }).toList(),
    );
  }
  void logout() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('userId');
  await prefs.remove('token');

  // Show a snackbar with the logout success message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Logout successfully'),
      duration: Duration(seconds: 2), // Optional: Set how long the snackbar will be visible
    ),
  );

  // Navigate to the HomePage
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) =>login()),
  );
}

 Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _filterOrdersByDateRange();
    }
  }

  void _filterOrdersByDateRange() {
    
  if (startDate != null && endDate != null) {
    setState(() {
      filteredOrders = goods.where((order) {
        final orderDate = DateTime.parse(order['shipped_date']);
        return (orderDate.isAtSameMomentAs(startDate!) ||
                orderDate.isAtSameMomentAs(endDate!) ||
                (orderDate.isAfter(startDate!) && orderDate.isBefore(endDate!)));
      }).toList();
    });
  }
}

  @override
  void initState() {
    super.initState();
    getgoodsdetails();
  }
Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

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
        appBar: AppBar(
      
             title: Text(
            "Daily Goods Movement",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back), // Custom back arrow
            onPressed: () async{
                      final dep= await getdepFromPrefs();
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
      }
      else {
      Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => dashboard()), // Replace AnotherPage with your target page
              );
      
      }
             
            },
          ),
      
          actions: [
              IconButton(
                icon: Image.asset('lib/assets/profile.png'),
                 
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>EditProfileScreen()));
                  
                },
              ),
            ],
            
            ),
      
        
        body: Column(
          children: [
      
            // Padding(
            //   padding: const EdgeInsets.all(10),
            //   child: Container(
            //           height: 46, 
            //           decoration: BoxDecoration(
            //             border: Border.all(
            //   color: Colors.blue, 
            //   width: 1.0, 
            //             ),
            //             borderRadius: BorderRadius.circular(8.0), 
            //           ),
            //           child: Row(
            //             children: [
            //   SizedBox(width: 25,),
            //   Text(
            //     '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
            //     style: TextStyle(fontSize:12,color:Color.fromARGB(255, 116, 116, 116)),
            //   ),
            //   SizedBox(width: 162,),
            //   GestureDetector(
            //     onTap: () {
            //     _selectDate(context);
            //       
            //     },
            //     child: Container(
            //       padding: const EdgeInsets.only(left: 55),
            //       child: Icon(Icons.date_range)),
            //   ),
            //             ],
            //           ),
            //         ),
            // ),  
      
             SizedBox(height: 10,),
               Padding(
                 padding: const EdgeInsets.only(right: 10),
                 child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                   children: [
                     ElevatedButton(
                       onPressed: () => _selectDateRange(context),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.blue, // Set button color to grey
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(8), // Set the border radius
                         ),
                       ),
                       child: Row(
                         mainAxisSize: MainAxisSize.min, // Ensures the Row takes only as much space as needed
                         children: [
                           Icon(
                             Icons.date_range, // Date range icon
                             color: Colors.white, // Icon color to match the text
                           ),
                           SizedBox(width: 8), // Add some spacing between the icon and text
                           Text(
                             'Select Date Range',
                             style: TextStyle(color: Colors.white), // Set text color to white
                           ),
                         ],
                       ),
                     ),
                   ],
                 ),
               ),
        
                       
            Expanded(
              child: filteredOrders.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: EdgeInsets.all(5.0),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final item = filteredOrders[index];
                        return GestureDetector(
                          onTap: () {
                                                            Navigator.push(context, MaterialPageRoute(builder: (context)=>Dgm(shipped_date: item['shipped_date'])));

                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 15),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade100, Colors.blue.shade300],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: Colors.blue.shade700),
                                    SizedBox(width: 8),
                                    Text(
                                      "Shipped Date: ${item['shipped_date']}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color.fromARGB(255, 32, 0, 0),
                                      ),
                                    ),
                                  ],
                                ),
                                 SizedBox(height: 5),
                                Row(
                                  children: [
                                    Icon(Icons.add_box, color: Colors.blue.shade700),
                                    SizedBox(width: 8),
                                    Text(
                                      "Total Boxes: ${item['total_boxes']}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.fitness_center, color: Colors.blue.shade700),
                                    SizedBox(width: 8),
                                    Text(
                                      "Total A/W: ${item['total_weight']} kg",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.fitness_center_sharp, color: Colors.blue.shade700),
                                    SizedBox(width: 8),
                                    Text(
                                      "Volume Weight: ${item['total_volume_weight']} kg",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.attach_money, color: Colors.blue.shade700),
                                    SizedBox(width: 8),
                                    Text(
                                      "Shipping Charge: ₹${item['total_shipping_charge']}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                // SizedBox(height: 10),
                                // ElevatedButton(onPressed: () {
                                //   Navigator.push(context, MaterialPageRoute(builder: (context)=>Dgm(shipped_date: item['shipped_date'])));
                                // }, child: Text("View")),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }}
