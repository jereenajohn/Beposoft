


// import 'package:beposoft/pages/ACCOUNTS/add_Recipt.dart';
// import 'package:beposoft/pages/ACCOUNTS/credit_note_list.dart';
// import 'package:beposoft/pages/BDO/bdo_customer_list.dart';
// import 'package:beposoft/pages/BDO/bdo_order_list.dart';
// import 'package:beposoft/pages/BDO/performa_invoice.dart';
// import 'package:flutter/material.dart';

// class logistics_dashbord extends StatefulWidget {
//   const logistics_dashbord({super.key});

//   @override
//   State<logistics_dashbord> createState() => _logistics_dashbordState();
// }

// class _logistics_dashbordState extends State<logistics_dashbord> {
  

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
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
          
//           children: [
//             Container(
//               width: 10, // Customize the width here
//               child: DrawerHeader(
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
//             ),
//             ListTile(
//               leading: Icon(Icons.dashboard),
//               title: Text('Dashboard'),
//               onTap: () {
//                 Navigator.push(context, MaterialPageRoute(builder: (context)=>logistics_dashbord()));

//               },
//             ),
           
             
           

//               ListTile(
//                 leading: Icon(Icons.receipt),
//                 title: Text('Delivery Note'),
              
//                 onTap: () {
//                   // Open the dropdown menu
//                   showModalBottomSheet(
//                     context: context,
//                     builder: (BuildContext context) {
//                       return Container(
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: <Widget>[
//                             ListTile(
//                               title: Text('Delivery notes list'),
//                               onTap: () {
//                                 Navigator.pop(context);
//                                 _navigateToSelectedPage(context, 'Option 1');
//                               },
//                             ),
//                             ListTile(
//                               title: Text('Daily Goods Movement '),
//                               onTap: () {
//                                 Navigator.pop(context);
//                                 _navigateToSelectedPage(context, 'Option 2');
//                               },
//                             ),
                            
                            
//                           ],
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
              
              
//                ListTile(
//                 leading: Icon(Icons.sports_basketball),
//                 title: Text('GRV'),
              
//                 onTap: () {
//                   // Open the dropdown menu
//                   showModalBottomSheet(
//                     context: context,
//                     builder: (BuildContext context) {
//                       return Container(
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: <Widget>[
//                             ListTile(
//                               title: Text('Create New'),
//                               onTap: () {
//                                 Navigator.pop(context);
//                                 _navigateToSelectedPage(context, 'Option 3');
//                               },
//                             ),
//                             ListTile(
//                               title: Text('GRVs List '),
//                               onTap: () {
//                                 Navigator.pop(context);
//                                 _navigateToSelectedPage(context, 'Option 4');
//                               },
//                             ),
                            
                            
//                           ],
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//                ListTile(
//               leading: Icon(Icons.chat),
//               title: Text('Chats'),
//               onTap: () {},
//             ),
              


              
//             ],
//           ),
//         ),
//         body: SingleChildScrollView(
//         child: Container(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.only(top: 20, left: 50),
//                 child: Text(
//                   "DASHBOARD",
//                   style: TextStyle(
//                     letterSpacing: 13.0,
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.only(top: 18,),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     Expanded(
//                       child: SizedBox(
//                         height: 140,
//                         child: Card(
//                           elevation: 3,
//                           child: GestureDetector(
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => add_receipt()),
//                               );
//                             },
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(10),
//                               color:  Color.fromARGB(255, 228, 195, 3)
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.only(left: 13),
//                                 child: Column(
//                                   children: [
//                                     SizedBox(height: 10,),
//                                     Text(
//                                       "Waiting For Packing ",
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: Colors.white,
//                                         fontSize: 16,
//                                       ),
//                                     ),
//                                     SizedBox(height: 15,),
//                                     Row(
//                                       children: [
//                                         Text(
//                                           "0",
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             color: Colors.white,
//                                             fontSize: 25,
//                                           ),
//                                         ),
                                       
//                                       ],
//                                     ),
//                                      Row(
                                      
//                                       children: [
//                                         SizedBox(width: 120,),
//                                         Image.asset(
//                                               "lib/assets/right.png",
//                                               width: 25,
//                                               height: 25,
//                                               fit: BoxFit.contain,
//                                             ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     Expanded(
//                       child: SizedBox(
//                         height: 140,
//                         child: Card(
//                           elevation: 3,
//                           child: GestureDetector(
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => add_receipt()),
//                               );
//                             },
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(10),
//                                 color: Color.fromARGB(255, 228, 195, 3)
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.only(left: 13),
//                                 child: Column(
//                                   children: [
//                                     SizedBox(height: 10,),
//                                     Text(
//                                       "Waiting For Shipping",
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: Colors.white,
//                                         fontSize: 16,
//                                       ),
//                                     ),
//                                     SizedBox(height: 15,),
//                                     Row(
//                                       children: [
//                                         Text(
//                                           "25/5",
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             color: Colors.white,
//                                             fontSize: 25,
//                                           ),
//                                         ),
                                       
//                                       ],
//                                     ),
//                                      Row(
                                      
//                                       children: [
//                                         SizedBox(width: 120,),
//                                         Image.asset(
//                                               "lib/assets/right.png",
//                                               width: 25,
//                                               height: 25,
//                                               fit: BoxFit.contain,
//                                             ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

            


              
         

 
            
//             ],
//           ),
//         ),
//       ),

//       );
    

//   }


   
// }
