
// import 'package:beposoft/loginpage.dart';
// import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
// import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
// import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
// import 'package:beposoft/pages/ACCOUNTS/add_family.dart';
// import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
// import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
// import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
// import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
// import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
// import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
// import 'package:flutter/material.dart';


// import 'package:flutter_colorpicker/flutter_colorpicker.dart';
// import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
// import 'package:beposoft/pages/ACCOUNTS/methods.dart';
// import 'package:shared_preferences/shared_preferences.dart';





// class Purchases_request extends StatefulWidget {
//   const Purchases_request({super.key});

//   @override
//   State<Purchases_request> createState() => _Purchases_requestState();
// }

// class _Purchases_requestState extends State<Purchases_request> {

//    List<String>  addedby = ["jeshiya",'nimitha','hanvi','sulfi','yeshitha'];
//   String selectaddby="jeshiya";
//   List<String>  purchasetype = ["Raw type",'For sale',];
//   String selecttype="Raw type";


// //dateselection
//    DateTime selectedDate = DateTime.now();

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//     }
//   }
//    drower d=drower();
//    Widget _buildDropdownTile(BuildContext context, String title, List<String> options) {
//     return ExpansionTile(
//       title: Text(title),
//       children: options.map((option) {
//         return ListTile(
//           title: Text(option),
//           onTap: () {
//             Navigator.pop(context);
//             d.navigateToSelectedPage(context, option); // Navigate to selected page
//           },
//         );
//       }).toList(),
//     );
//   }


//   //searchable dropdown

//  final List<String> items = [
//     'A_Item1',
//     'A_Item2',
//     'A_Item3',
//     'A_Item4',
//     'B_Item1',
//     'B_Item2',
//     'B_Item3',
//     'B_Item4',
//     "anii"
//   ];

//   String? selectedValue;
//   final TextEditingController textEditingController = TextEditingController();

//   @override
//   void dispose() {
//     textEditingController.dispose();
//     super.dispose();
//   }
//   List<String>  company = ["BEPOSITIVE RACING PRIVATE LIMITED",'MICHAEL EXPORT AND IMPORT PRIVATE LIMITED'];
//   String selectcomp="BEPOSITIVE RACING PRIVATE LIMITED";
//   void logout() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   await prefs.remove('userId');
//   await prefs.remove('token');

//   // Use a post-frame callback to show the SnackBar after the current frame
//   WidgetsBinding.instance.addPostFrameCallback((_) {
//     if (ScaffoldMessenger.of(context).mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Logged out successfully'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//     }
//   });

//   // Wait for the SnackBar to disappear before navigating
//   await Future.delayed(Duration(seconds: 2));

//   // Navigate to the HomePage after the snackbar is shown
//   Navigator.pushReplacement(
//     context,
//     MaterialPageRoute(builder: (context) => login()),
//   );
// }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(


//       backgroundColor: Color.fromARGB(242, 255, 255, 255),
//       appBar: AppBar(

//         actions: [
//             IconButton(
//               icon: Image.asset('lib/assets/profile.png'),
               
//               onPressed: () {
                
//               },
//             ),
//           ],
          
//           ),
//          drawer: Drawer(
//           child: ListView(
//             padding: EdgeInsets.zero,
//             children: <Widget>[
//               DrawerHeader(
//                   decoration: BoxDecoration(
//                     color: Colors.grey[200],
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Image.asset(
//                         "lib/assets/logo.png",
//                         width: 150, // Change width to desired size
//                         height: 150, // Change height to desired size
//                         fit: BoxFit
//                             .contain, // Use BoxFit.contain to maintain aspect ratio
//                       ),
//                     ],
//                   )),
//               ListTile(
//                 leading: Icon(Icons.dashboard),
//                 title: Text('Dashboard'),
//                 onTap: () {
//                   Navigator.push(context,
//                       MaterialPageRoute(builder: (context) => dashboard()));
//                 },
//               ),
             
//               ListTile(
//                 leading: Icon(Icons.person),
//                 title: Text('Company'),
//                 onTap: () {
//                   Navigator.push(context,
//                       MaterialPageRoute(builder: (context) => add_company()));
//                   // Navigate to the Settings page or perform any other action
//                 },
//               ),
//               ListTile(
//                 leading: Icon(Icons.person),
//                 title: Text('Departments'),
//                 onTap: () {
//                   Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (context) => add_department()));
//                   // Navigate to the Settings page or perform any other action
//                 },
//               ),
//               ListTile(
//                 leading: Icon(Icons.person),
//                 title: Text('Supervisors'),
//                 onTap: () {
//                   Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (context) => add_supervisor()));
//                   // Navigate to the Settings page or perform any other action
//                 },
//               ),
//               ListTile(
//                 leading: Icon(Icons.person),
//                 title: Text('Family'),
//                 onTap: () {
//                   Navigator.push(context,
//                       MaterialPageRoute(builder: (context) => add_family()));
//                   // Navigate to the Settings page or perform any other action
//                 },
//               ),
//               ListTile(
//                 leading: Icon(Icons.person),
//                 title: Text('Bank'),
//                 onTap: () {
//                   Navigator.push(context,
//                       MaterialPageRoute(builder: (context) => add_bank()));
//                   // Navigate to the Settings page or perform any other action
//                 },
//               ),
//               ListTile(
//                 leading: Icon(Icons.person),
//                 title: Text('States'),
//                 onTap: () {
//                   Navigator.push(context,
//                       MaterialPageRoute(builder: (context) => add_state()));
//                   // Navigate to the Settings page or perform any other action
//                 },
//               ),
//               ListTile(
//                 leading: Icon(Icons.person),
//                 title: Text('Attributes'),
//                 onTap: () {
//                   Navigator.push(context,
//                       MaterialPageRoute(builder: (context) => add_attribute()));
//                   // Navigate to the Settings page or perform any other action
//                 },
//               ),
//               ListTile(
//                 leading: Icon(Icons.person),
//                 title: Text('Services'),
//                 onTap: () {
//                   Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (context) => CourierServices()));
//                   // Navigate to the Settings page or perform any other action
//                 },
//               ),
//                ListTile(
//                 leading: Icon(Icons.person),
//                 title: Text('Delivery Notes'),
//                 onTap: () {
//                   Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (context) => WarehouseOrderView(status: null,)));
//                   // Navigate to the Settings page or perform any other action
//                 },
//               ),
//               Divider(),
//               _buildDropdownTile(context, 'Reports', [
//                 'Sales Report',
//                 'Credit Sales Report',
//                 'COD Sales Report',
//                 'Statewise Sales Report',
//                 'Expence Report',
//                 'Delivery Report',
//                 'Product Sale Report',
//                 'Stock Report',
//                 'Damaged Stock'
//               ]),
//               _buildDropdownTile(context, 'Customers', [
//                 'Add Customer',
//                 'Customers',
//               ]),
//               _buildDropdownTile(context, 'Staff', [
//                 'Add Staff',
//                 'Staff',
//               ]),
//               _buildDropdownTile(context, 'Credit Note', [
//                 'Add Credit Note',
//                 'Credit Note List',
//               ]),
//               _buildDropdownTile(context, 'Proforma Invoice', [
//                 'New Proforma Invoice',
//                 'Proforma Invoice List',
//               ]),
//               _buildDropdownTile(context, 'Delivery Note',
//                   ['Delivery Note List', 'Daily Goods Movement']),
//               _buildDropdownTile(
//                   context, 'Orders', ['New Orders', 'Orders List']),
//               Divider(),
//               Text("Others"),
//               Divider(),
//               _buildDropdownTile(context, 'Product', [
//                 'Product List',
//                 'Product Add',
//                 'Stock',
//               ]),
//               _buildDropdownTile(context, 'Expence', [
//                 'Add Expence',
//                 'Expence List',
//               ]),
//               _buildDropdownTile(
//                   context, 'GRV', ['Create New GRV', 'GRVs List']),
//               _buildDropdownTile(context, 'Banking Module',
//                   ['Add Bank ', 'List', 'Other Transfer']),
//               Divider(),
//               ListTile(
//                 leading: Icon(Icons.settings),
//                 title: Text('Methods'),
//                 onTap: () {
//                   Navigator.push(context,
//                       MaterialPageRoute(builder: (context) => Methods()));
//                 },
//               ),
//               ListTile(
//                 leading: Icon(Icons.chat),
//                 title: Text('Chat'),
//                 onTap: () {
//                   Navigator.pop(context); // Close the drawer
//                 },
//               ),
//               Divider(),
//               ListTile(
//                 leading: Icon(Icons.exit_to_app),
//                 title: Text('Logout'),
//                 onTap: () {
//                   logout();
//                 },
//               ),
//             ],
//           ),
//         ),

//         body: SingleChildScrollView(

//           child: Container(
//             child: Column(
//               children: [
//                 SizedBox(height: 15,),


//                 Text("PURCHASES REQUEST ",style: TextStyle(fontSize: 20,letterSpacing: 7.0,fontWeight: FontWeight.bold),),

//                 Padding(
//                   padding: const EdgeInsets.only(top: 25,left: 15,right: 15),
//                 child:Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(10.0),
//                     border: Border.all(color: Color.fromARGB(255, 202, 202, 202)),
                    
//                   ),
//                   width: 700,

//                   child: Padding(
//                     padding: const EdgeInsets.only(left: 10),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
                       
                    
//                         SizedBox(height: 10,),
//                            Text("Purchase type",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
//                             SizedBox(height: 10,),




              
//                           Container(
//                     width: 304,
//                     height: 49,
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Row(
//                       children: [
//                         SizedBox(width: 20),
//                         Container(
//                           width: 276,
//                           child: InputDecorator(
//                             decoration: InputDecoration(
//                               border: InputBorder.none,
//                               hintText: '',
//                               contentPadding: EdgeInsets.symmetric(horizontal: 1),
//                             ),
//                             child: DropdownButton<String>(
//                               value: selecttype,
//                               underline: Container(), // This removes the underline
//                               onChanged: (String? newValue) {
//                                 setState(() {
//                                   selecttype = newValue!;
                                  
//                                 });
//                               },
//                               items: purchasetype.map<DropdownMenuItem<String>>((String value) {
//                                 return DropdownMenuItem<String>(
//                                   value: value,
//                                   child: Text(value),
//                                 );
//                               }).toList(),
//                               icon: Container(
//                                 padding: EdgeInsets.only(left: 170), // Adjust padding as needed
//                                 alignment: Alignment.centerRight,
//                                 child: Icon(Icons.arrow_drop_down), // Dropdown arrow icon
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),


//                     SizedBox(height: 10,),
//                            Text("Supplier Name",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
//                             SizedBox(height: 10,),
                    
//                             Container(
//                               width: 304,
//                               child:  TextField(
//                                   decoration: InputDecoration(
//                                     labelText: '',
//                                     prefixIcon: Icon(Icons.build_circle),
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(10.0),
//                                       borderSide: BorderSide(color: Colors.grey),
//                                     ),
//                                     contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
//                                   ),
//                                 ),
                    
//                             ),


//                              SizedBox(height: 10,),
//                            Text("Invoice ID",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
//                             SizedBox(height: 10,),
                    
//                             Container(
//                               width: 304,
//                               child:  TextField(
//                                   decoration: InputDecoration(
//                                     labelText: '',
//                                     prefixIcon: Icon(Icons.local_activity),
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(10.0),
//                                       borderSide: BorderSide(color: Colors.grey),
//                                     ),
//                                     contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
//                                   ),
//                                 ),
                    
//                             ),
                    
                    



                      
                           
// SizedBox(height: 10,),
//                  Text("Invoice Date",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
//                   SizedBox(height: 10,),

//  Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Container(
//   width: 304, // Set the desired width here
//   height: 46, // Set the desired height here
//   decoration: BoxDecoration(
//     border: Border.all(
//       color: Colors.grey, // You can set the border color here
//       width: 1.0, // You can adjust the border width here
//     ),
//     borderRadius: BorderRadius.circular(8.0), // You can adjust the border radius here
//   ),
//   child: Row(
//     children: [
//       SizedBox(width: 25,),
//       Text(
//         '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
//         style: TextStyle(fontSize:15,color:Color.fromARGB(255, 116, 116, 116)),
//       ),
//       SizedBox(width: 162,),
//        GestureDetector(
//         onTap: () {
//          _selectDate(context);
          
//         },
//         child: Icon(Icons.date_range),
//       ),
//     ],
//   ),
// ),

           
           
//           ],
//         ),


                        
                    
//                         SizedBox(height: 10,),
//                            Text("Label",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
//                             SizedBox(height: 10,),
                    
//                             Container(
//                               width: 304,
//                               child:  TextField(
//                                   decoration: InputDecoration(
//                                     labelText: '',
//                                     prefixIcon: Icon(Icons.local_offer),
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(10.0),
//                                       borderSide: BorderSide(color: Colors.grey),
//                                     ),
//                                     contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
//                                   ),
//                                 ),
                    
//                             ),
//                               SizedBox(height: 10,),


//                                                             SizedBox(height: 10,),
//                          Text("Technical manager",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
//                           SizedBox(height: 10,),


//                           Container(
//                     width: 310,
//                     height: 49,
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Row(
//                       children: [
//                         SizedBox(width: 20),
//                         Container(
//                           width: 276,
//                           child: InputDecorator(
//                             decoration: InputDecoration(
//                               border: InputBorder.none,
//                               hintText: '',
//                               contentPadding: EdgeInsets.symmetric(horizontal: 1),
//                             ),
//                             child: DropdownButton<String>(
//                               value: selectaddby,
//                               underline: Container(), // This removes the underline
//                               onChanged: (String? newValue) {
//                                 setState(() {
//                                   selectaddby = newValue!;
                                  
//                                 });
//                               },
//                               items: addedby.map<DropdownMenuItem<String>>((String value) {
//                                 return DropdownMenuItem<String>(
//                                   value: value,
//                                   child: Text(value),
//                                 );
//                               }).toList(),
//                               icon: Container(
//                                 padding: EdgeInsets.only(left: 167), // Adjust padding as needed
//                                 alignment: Alignment.centerRight,
//                                 child: Icon(Icons.arrow_drop_down), // Dropdown arrow icon
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
                           


//                             SizedBox(height: 10,),

                  

//          SizedBox(height: 20,),

//                  Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     height: 1,
//                     width: 300,
//                     color: Color.fromARGB(255, 215, 201, 201),
//                   ),
                  
                  
//                 ],
//               ),
              

//               SizedBox(height: 25,),
             
                
                     
                
//                    SizedBox(height: 15,),

//                    Row(
//                      children:[
//                       SizedBox(width: 20,),

//                       SizedBox(
//                       width: 270,
//                        child: ElevatedButton(
//                                          onPressed: () {
//                         // Your onPressed logic goes here
//                                          },
//                                          style: ButtonStyle(
//                         backgroundColor: MaterialStateProperty.all<Color>(
//                           Color.fromARGB(255, 3, 173, 20),
//                         ),
//                         shape: MaterialStateProperty.all<RoundedRectangleBorder>(
//                           RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10), // Set your desired border radius
//                           ),
//                         ),
//                         fixedSize: MaterialStateProperty.all<Size>(
//                           Size(95, 15), // Set your desired width and heigh
//                         ),
//                                          ),
//                                          child: Text("Add New Purchase",style: TextStyle(color: Colors.white)),
//                                        ),
//                      ),
//                      ] 
//                    ),
//                 SizedBox(height: 20,)


                           
              








         
                    
                            
                    
//                       ],
//                     ),
//                   )
                  
  
  
// ),

//                 ),

               

//               ],
//             ),
//           )

//         ),


//     );
//   }


 

// }