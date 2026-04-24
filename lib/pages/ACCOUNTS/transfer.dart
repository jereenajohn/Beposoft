
// import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
// import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
// import 'package:flutter/material.dart';

// import 'package:flutter_colorpicker/flutter_colorpicker.dart';



// import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
// import 'package:beposoft/pages/ACCOUNTS/new_grv.dart';
// import 'package:beposoft/pages/ACCOUNTS/profile.dart';
// import 'package:beposoft/pages/ACCOUNTS/transfer.dart';




// import 'package:beposoft/main.dart';
// import 'package:beposoft/pages/ACCOUNTS/add_credit_note.dart';
// import 'package:beposoft/pages/ACCOUNTS/add_recipts.dart';
// import 'package:beposoft/pages/ACCOUNTS/customer.dart';
// import 'package:beposoft/pages/ACCOUNTS/recipts_list.dart';
// import 'package:beposoft/pages/ACCOUNTS/add_new_stock.dart';
// import 'package:beposoft/pages/ACCOUNTS/credit_note_list.dart';
// import 'package:beposoft/pages/ACCOUNTS/expence.dart';
// import 'package:beposoft/pages/ACCOUNTS/methods.dart';
// import 'package:beposoft/pages/ACCOUNTS/new_product.dart';
// import 'package:beposoft/pages/ACCOUNTS/order_request.dart';
// import 'package:beposoft/pages/ACCOUNTS/purchases_request.dart';
// import 'package:dropdown_button2/dropdown_button2.dart';
// import 'package:beposoft/pages/ACCOUNTS/add_new_customer.dart';

// class transfer extends StatefulWidget {
//   const transfer({super.key});

//   @override
//   State<transfer> createState() => _transferState();
// }

// class _transferState extends State<transfer> {

  
//    List<String>  bank = ["ICIC",'SBI','HDFC'];
//   String selectbank="ICIC";
   
//    List<String>  type = ["Credit",'Debit'];
//   String selecttype="Credit";

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
//  drower d=drower();
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
//   String? selectedValue;
//   final TextEditingController textEditingController = TextEditingController();

//   @override
//   void dispose() {
//     textEditingController.dispose();
//     super.dispose();
//   }
//   List<String>  company = ["BEPOSITIVE RACING PRIVATE LIMITED",'MICHAEL EXPORT AND IMPORT PRIVATE LIMITED'];
//   String selectcomp="BEPOSITIVE RACING PRIVATE LIMITED";
  

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
//      drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: <Widget>[
//             DrawerHeader(
//                   decoration: BoxDecoration(
//                     color: const Color.fromARGB(255, 110, 110, 110),
//                   ),
//                   child: Row(
//                     children: [
//                       Image.asset(
//                         "lib/assets/logo-white.png",
//                         width: 100, // Change width to desired size
//                         height: 100, // Change height to desired size
//                         fit: BoxFit
//                             .contain, // Use BoxFit.contain to maintain aspect ratio
//                       ),
//                       SizedBox(width: 70,),
//                       Text(
//                         'BepoSoft',
//                         style: TextStyle(
//                           color: Color.fromARGB(236, 255, 255, 255),
//                           fontSize: 20,
                         
//                         ),
//                       ),
                      
//                     ],
//                   )),
//                   ListTile(
//               leading: Icon(Icons.dashboard),
//               title: Text('Dashboard'),
//               onTap: () {
//                 Navigator.push(context, MaterialPageRoute(builder: (context)=>dashboard()));
//               },
//             ),
//                   ListTile(
//               leading: Icon(Icons.person),
//               title: Text('Customer'),
//               onTap: () {
//                 Navigator.push(context, MaterialPageRoute(builder: (context)=>customer_list()));
//                 // Navigate to the Settings page or perform any other action
//               },
//             ),
//              Divider(),
//             _buildDropdownTile(context, 'Credit Note', ['Add Credit Note', 'Credit Note List',]),
//             _buildDropdownTile(context, 'Recipts', ['Add recipts', 'Recipts List']),
//             _buildDropdownTile(context, 'Proforma Invoice', ['New Proforma Invoice', 'Proforma Invoice List',]),
//             _buildDropdownTile(context, 'Delivery Note', ['Delivery Note List', 'Daily Goods Movement']),
//             _buildDropdownTile(context, 'Orders', ['New Orders', 'Orders List']),
//              Divider(),

//              Text("Others"),
//              Divider(),

//             _buildDropdownTile(context, 'Product', ['Product List', 'Stock',]),
//             _buildDropdownTile(context, 'Purchase', [' New Purchase', 'Purchase List']),
//             _buildDropdownTile(context, 'Expence', ['Add Expence', 'Expence List',]),
//             _buildDropdownTile(context, 'Reports', ['Sales Report', 'Credit Sales Report','COD Sales Report','Statewise Sales Report','Expence Report','Delivery Report','Product Sale Report','Stock Report','Damaged Stock']),
//             _buildDropdownTile(context, 'GRV', ['Create New GRV', 'GRVs List']),
//              _buildDropdownTile(context, 'Banking Module', ['Add Bank ', 'List','Other Transfer']),
//                Divider(),




//             ListTile(
//               leading: Icon(Icons.settings),
//               title: Text('Methods'),
//               onTap: () {
//                Navigator.push(context, MaterialPageRoute(builder: (context)=>Methods()));

//               },
//             ),

//             ListTile(
//               leading: Icon(Icons.chat),
//               title: Text('Chat'),
//               onTap: () {
//                 Navigator.pop(context); // Close the drawer
//               },
//             ),
//             Divider(),
//             ListTile(
//               leading: Icon(Icons.exit_to_app),
//               title: Text('Logout'),
//               onTap: () {
//                 Navigator.pop(context); // Close the drawer
//                 // Perform logout action
//               },
//             ),
            
          
//           ],
//         ),
//       ),

//         body: SingleChildScrollView(
//           child: Container(
//             child: Column(
//               children: [
//                 SizedBox(height: 15,),


//                 Center(child: Text("OTHER BANK CREDITS AND DEBITS ",style: TextStyle(fontSize: 15,letterSpacing: 3.0,fontWeight: FontWeight.bold),)),

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
//                         Padding(
//                       padding: const EdgeInsets.only(right: 10,top:10,),
//                       child: Container(
//                         width: 600,
                    
//                          decoration: BoxDecoration(
//                       color: Color.fromARGB(255, 121, 121, 121),
                     
//                       border: Border.all(color: Color.fromARGB(255, 202, 202, 202)),
                      
//                     ),
//                         child: Column(
//                           children: [
//                             SizedBox(height: 10,),
//                             Text(" Transfers",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.white),),
//                             SizedBox(height: 13,),
                    
                            
                        
                    
                          
                          
                         
                    
                    
                    
                    
//                           ],
//                         ),
//                       ),
//                     ),
                    
                    
//                   SizedBox(height: 10,),
//                            Text("Amount",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
//                             SizedBox(height: 10,),
                    
//                             Container(
//                               width: 304,
//                               child:  TextField(
//                                   decoration: InputDecoration(
//                                     labelText: 'Amount',
//                                     prefixIcon: Icon(Icons.currency_rupee_sharp),
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(10.0),
//                                       borderSide: BorderSide(color: Colors.grey),
//                                     ),
//                                     contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
//                                   ),
//                                 ),
                    
//                             ),  
//                              SizedBox(height: 25,),
             
//                  Text("Credit Or Debit",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
//               SizedBox(height: 10,),

              
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
//                                   
//                                 });
//                               },
//                               items: type.map<DropdownMenuItem<String>>((String value) {
//                                 return DropdownMenuItem<String>(
//                                   value: value,
//                                   child: Text(value),
//                                 );
//                               }).toList(),
//                               icon: Container(
//                                 padding: EdgeInsets.only(left: 190), // Adjust padding as needed
//                                 alignment: Alignment.centerRight,
//                                 child: Icon(Icons.arrow_drop_down), // Dropdown arrow icon
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),   
// SizedBox(height: 10,),
//                  Text("Payement Date",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
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
//       SizedBox(width: 30,),
//       Text(
//         '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
//         style: TextStyle(fontSize:15,color:Color.fromARGB(255, 116, 116, 116)),
//       ),
//       SizedBox(width: 162,),
//        GestureDetector(
//         onTap: () {
//          _selectDate(context);
//           
//         },
//         child: Icon(Icons.date_range),
//       ),
//     ],
//   ),
// ),

           
           
//           ],
//         ),

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
//                 SizedBox(height: 20,),

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

//                 SizedBox(height: 25,),
             
//                  Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                                       Text("Transaction Details",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),)

//                   ],
//                  ),
              

              

//               SizedBox(height: 25,),
             
//                  Text("Bank Name",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
//               SizedBox(height: 10,),

              
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
//                               value: selectbank,
//                               underline: Container(), // This removes the underline
//                               onChanged: (String? newValue) {
//                                 setState(() {
//                                   selectbank = newValue!;
//                                   
//                                 });
//                               },
//                               items: bank.map<DropdownMenuItem<String>>((String value) {
//                                 return DropdownMenuItem<String>(
//                                   value: value,
//                                   child: Text(value),
//                                 );
//                               }).toList(),
//                               icon: Container(
//                                 padding: EdgeInsets.only(left: 190), // Adjust padding as needed
//                                 alignment: Alignment.centerRight,
//                                 child: Icon(Icons.arrow_drop_down), // Dropdown arrow icon
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: 10,),
//                  Text("Transaction Id",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
//               SizedBox(height: 10,),

//               Container(
//                     width: 304, 
//                     child: TextField(
//                       decoration: InputDecoration(
//                         labelText: '',
//                         prefixIcon: Icon(Icons.numbers),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10.0),
//                           borderSide: BorderSide(color: Colors.grey),
//                         ),
//                         contentPadding: EdgeInsets.symmetric(vertical: 8.0),
//                       ),
//                     ),
//                   ),

//               SizedBox(height: 15,),
//                 Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     height: 1,
//                     width: 300,
//                     color: Color.fromARGB(255, 215, 201, 201),
//                   ),
                  
                  
//                 ],
//               ),
//               SizedBox(height: 15,),

//               Text("Description ",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
//                           SizedBox(height: 20,),


//                            TextField(
//                                 decoration: InputDecoration(
//                                   labelText: 'Enter',
//                                    prefixIcon: Icon(Icons.local_offer),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10.0),
//                                     borderSide: BorderSide(color: Colors.grey),
//                                   ),
//                                   contentPadding: EdgeInsets.symmetric(vertical: 8.0),
//                                 ),
//                                 maxLines: null, // Set maxLines to null for a multi-line text input
//                               ),


             
//                    SizedBox(height: 15,),

//                    ElevatedButton(
//                   onPressed: () {
//                     // Your onPressed logic goes here
//                   },
//                   style: ButtonStyle(
//                     backgroundColor: MaterialStateProperty.all<Color>(
//                       Color.fromARGB(255, 244, 66, 66),
//                     ),
//                     shape: MaterialStateProperty.all<RoundedRectangleBorder>(
//                       RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10), // Set your desired border radius
//                       ),
//                     ),
//                     fixedSize: MaterialStateProperty.all<Size>(
//                       Size(95, 15), // Set your desired width and heigh
//                     ),
//                   ),
//                   child: Text("Submit",style: TextStyle(color: Colors.white)),
//                 ),
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
//       );
    

//   }

//    void _navigateToSelectedPage(BuildContext context, String selectedOption) {
    
//     switch (selectedOption) {
//       case 'Option 1':
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => add_credit_note()),
//         );
//         break;
//       case 'Option 2':
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) =>credit_note_list()),
//         );
//         break;
//         case 'Option 3':
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => add_receipts()),
//         );
//         break;
//         case 'Option 4':
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => receips()),
//         );
//         break;
//          case 'Option 5':
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => receips()),
//         );
//         break;
//          case 'Option 6':
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => receips()),
//         );
//         break;
//          case 'Option 7':
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => order_request()),
//         );
//         break;
//          case 'Option 8':
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => new_product()),
//         );
//         break;
//         case 'Option 9':
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => new_product()),
//         );
//         break;
//         case 'Option 10':
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => add_new_stock()),
//         );
//         break;
//         case 'Option 11':
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) =>  Purchases_request()),
//         );
//         break;
//         case 'Option 12':
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) =>  Purchases_request()),
//         );
//         break;
//         case 'Option 13':
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) =>  expence()),
//         );
//         break;
//         case 'Option 13':
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) =>  expence()),
//         );
//         break;
        
        
    
      
//       default:
//         // Handle default case or unexpected options
//         break;
//     }
//   }


   
// }
