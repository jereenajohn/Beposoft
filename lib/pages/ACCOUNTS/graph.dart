// import 'dart:convert';

// import 'package:beposoft/pages/api.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'package:fl_chart/fl_chart.dart';

// class Graph extends StatefulWidget {
//   const Graph({super.key});

//   @override
//   State<Graph> createState() => _GraphState();
// }

// class _GraphState extends State<Graph> {
//   @override
//   void initState() {
//     super.initState();
//     fetchOrderData();
//   }

//   Future<String?> getTokenFromPrefs() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getString('token');
//   }

//   bool isLoading = true;
//   List<Map<String, dynamic>> orders = [];
//   Map<String, int> monthlyOrders = {};
// Future<void> fetchOrderData() async {
//   try {
//     final token = await getTokenFromPrefs();
//     var response = await http.get(
//       Uri.parse('$api/api/orders/'),
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//     );

//     if (response.statusCode == 200) {
      
//       final parsed = jsonDecode(response.body);

//       // Ensure parsed data is a List<Map<String, dynamic>>
//       List<Map<String, dynamic>> productsData =
//           List<Map<String, dynamic>>.from(parsed);

//       // Map to store order counts and total amounts by month
//       Map<String, Map<String, dynamic>> monthlyOrderData = {};

//       for (var productData in productsData) {
//         String rawOrderDate = productData['order_date'];
//         double totalAmount = productData['total_amount'] ?? 0.0;

//         try {
//           // Parse the order date
//           DateTime parsedOrderDate = DateTime.parse(rawOrderDate);

//           // Format the date to "YYYY-MM" for monthly grouping
//           String monthKey =
//               "${parsedOrderDate.year}-${parsedOrderDate.month.toString().padLeft(2, '0')}";

//           // Initialize data for the month if not present
//           if (!monthlyOrderData.containsKey(monthKey)) {
//             monthlyOrderData[monthKey] = {'count': 0, 'totalAmount': 0.0};
//           }

//           // Increment the count and add to the total amount for this month
//           monthlyOrderData[monthKey]!['count'] += 1;
//           monthlyOrderData[monthKey]!['totalAmount'] += totalAmount;
//         } catch (e) {
          
//         }
//       }

      

//       // Update state with monthly order data
//       setState(() {
//         orders = productsData;
//         monthlyOrders = monthlyOrderData.map((key, value) =>
//             MapEntry(key, value['count'])); // Extract counts for graph
//         isLoading = false;
//       });
//     } else {
      
//       setState(() {
//         isLoading = false;
//       });
//     }
//   } catch (error) {
    
//     setState(() {
//       isLoading = false;
//     });
//   }
// }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Monthly Orders Graph'),
//       ),
//      body: isLoading
//     ? const Center(child: CircularProgressIndicator())
//     : monthlyOrders.isEmpty
//         ? const Center(child: Text('No data available'))
//         : Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Center(
//               child: SizedBox(
//                 width: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
//                 height: MediaQuery.of(context).size.height * 0.5, // 50% of screen height
//                 child: BarChart(
//                   BarChartData(
//                     alignment: BarChartAlignment.spaceAround,
//                     maxY: monthlyOrders.values.isNotEmpty
//                         ? (monthlyOrders.values.reduce((a, b) => a > b ? a : b) + 1).toDouble()
//                         : 1,
//                     barGroups: monthlyOrders.entries.map((entry) {
//                       String month = entry.key; // Example: "2025-01"
//                       int count = entry.value;

//                       return BarChartGroupData(
//                         x: int.parse(month.split('-')[1]), // Use the month number as x-axis value
//                         barRods: [
//                           BarChartRodData(
//                             toY: count.toDouble(),
//                             color: Colors.blue,
//                             width: 16,
//                             borderRadius: const BorderRadius.all(Radius.circular(4)),
//                           ),
//                         ],
//                       );
//                     }).toList(),
//                     titlesData: FlTitlesData(
//                       leftTitles: AxisTitles(
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           reservedSize: 40,
//                           getTitlesWidget: (value, meta) {
//                             return Padding(
//                               padding: const EdgeInsets.only(right: 8.0),
//                               child: Text(
//                                 value.toInt().toString(),
//                                 style: const TextStyle(
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       bottomTitles: AxisTitles(
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           reservedSize: 40,
//                           getTitlesWidget: (value, meta) {
//                             String text;
//                             switch (value.toInt()) {
//                               case 1:
//                                 text = 'Jan';
//                                 break;
//                               case 2:
//                                 text = 'Feb';
//                                 break;
//                               case 3:
//                                 text = 'Mar';
//                                 break;
//                               case 4:
//                                 text = 'Apr';
//                                 break;
//                               case 5:
//                                 text = 'May';
//                                 break;
//                               case 6:
//                                 text = 'Jun';
//                                 break;
//                               case 7:
//                                 text = 'Jul';
//                                 break;
//                               case 8:
//                                 text = 'Aug';
//                                 break;
//                               case 9:
//                                 text = 'Sep';
//                                 break;
//                               case 10:
//                                 text = 'Oct';
//                                 break;
//                               case 11:
//                                 text = 'Nov';
//                                 break;
//                               case 12:
//                                 text = 'Dec';
//                                 break;
//                               default:
//                                 text = '';
//                             }
//                             return Text(
//                               text,
//                               style: const TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       topTitles: AxisTitles(
//                         sideTitles: SideTitles(showTitles: false),
//                       ),
//                       rightTitles: AxisTitles(
//                         sideTitles: SideTitles(showTitles: false),
//                       ),
//                     ),
//                     borderData: FlBorderData(show: false),
//                     gridData: FlGridData(show: true),
//                   ),
//                 ),
//               ),
//             ),
//           ),

//     );
//   }
// }
