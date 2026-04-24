// import 'package:beposoft/pages/api.dart';
// import 'package:call_log/call_log.dart' as call_log;
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart'; // Add this for formatting
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:jwt_decoder/jwt_decoder.dart';

// class CallLog extends StatefulWidget {
//   @override
//   _CallLogState createState() => _CallLogState();
// }

// class _CallLogState extends State<CallLog> {
//   List<call_log.CallLogEntry> _callLogs = [];
//   Map<String, List<call_log.CallLogEntry>> _logsByHour = {};

//   DateTime? _startTime;
//   DateTime? _endTime;
//   int _totalCalls = 0;
//   int _totalDuration = 0;
//   int _totalActiveCalls = 0;

//   final TextEditingController _dialogController = TextEditingController();

//   @override
//   void dispose() {
//     _dialogController.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchCallLogs() async {
//     if (_startTime == null || _endTime == null) return;
//     try {
//       var entries = await call_log.CallLog.get();
//       setState(() {
//         _callLogs = List<call_log.CallLogEntry>.from(
//           entries.where((entry) {
//             if (entry.timestamp == null) return false;
//             final date = DateTime.fromMillisecondsSinceEpoch(entry.timestamp!);
//             return date.isAfter(_startTime!) && date.isBefore(_endTime!);
//           }),
//         );
//         _groupLogsByHour();
//       });
//     } catch (e) {
//     }
//   }

//   Future<String?> gettokenFromPrefs() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getString('token');
//   }

//   void uploadcalllog(BuildContext context, call_log.CallLogEntry log, String billCount, {bool showSnackbar = true}) async {
  
// final formattedStartTime = _startTime != null
//     ? DateFormat('yyyy-MM-dd HH:mm:ss').format(_startTime!)
//     : DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

// final formattedEndTime = _endTime != null
//     ? DateFormat('yyyy-MM-dd HH:mm:ss').format(_endTime!)
//     : DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());



//     final token = await gettokenFromPrefs();
//     Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
//     var id = decodedToken['id'];
//     try {
//       var response = await http.post(
//         Uri.parse('$api/api/call-log/create/$id/'),
//         headers: {
//           'Authorization': 'Bearer $token',
//         },
//         body: {
//           "customer_name": (log.name == null || log.name!.trim().isEmpty) ? "Unknown" : log.name,
//           "phone_number": log.number ?? "Unknown",
//           "call_duration_seconds": log.duration?.toString() ?? "0",
//           'call_date': log.timestamp != null
//               ? DateFormat('yyyy-MM-dd').format(
//                   DateTime.fromMillisecondsSinceEpoch(log.timestamp!))
//               : DateFormat('yyyy-MM-dd').format(DateTime.now()),
//           "start_time":formattedStartTime,
//           "end_time": formattedEndTime,
//           "active_calls": _totalActiveCalls.toString(),
//           "bill_count": billCount.isNotEmpty ? billCount : "0",
//         },
//       );
   

//       if (response.statusCode == 201 && showSnackbar) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             backgroundColor: Color.fromARGB(255, 49, 212, 4),
//             content: Text('Success! Call log uploaded.'),
//           ),
//         );
//         setState(() {
//           _startTime = null;
//           _endTime = null;
//         });
//         await _fetchCallLogs();
//         _logsByHour.clear();
//       }
//     } catch (e) {
     
//       if (showSnackbar) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             backgroundColor: Colors.red,
//             content: Text('An error occurred. Please try again.'),
//           ),
//         );
//       }
//     }
//   }

//   void _groupLogsByHour() {
//     _logsByHour.clear();
//     _totalCalls = 0;
//     _totalDuration = 0;
//     _totalActiveCalls = 0;

//     for (var entry in _callLogs) {
//       if (entry.timestamp != null) {
//         final date = DateTime.fromMillisecondsSinceEpoch(entry.timestamp!);
//         final hourKey = DateFormat('yyyy-MM-dd HH:00').format(date);
//         _logsByHour.putIfAbsent(hourKey, () => []).add(entry);
//       }

//       _totalCalls += 1;
//       final duration = entry.duration ?? 0;
//       _totalDuration += duration;
//       if (duration > 0) {
//         _totalActiveCalls += 1;
//       }
//     }
//   }

//   Future<void> _selectStartTime(BuildContext context) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _startTime ?? DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) {
//       final time = await showTimePicker(
//         context: context,
//         initialTime: TimeOfDay.fromDateTime(_startTime ?? DateTime.now()),
//       );
//       if (time != null) {
//         setState(() {
//           _startTime = DateTime(
//             picked.year,
//             picked.month,
//             picked.day,
//             time.hour,
//             time.minute,
//           );
//         });
//       }
//     }
//   }

//   Future<void> _selectEndTime(BuildContext context) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _endTime ?? DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) {
//       final time = await showTimePicker(
//         context: context,
//         initialTime: TimeOfDay.fromDateTime(_endTime ?? DateTime.now()),
//       );
//       if (time != null) {
//         setState(() {
//           _endTime = DateTime(
//             picked.year,
//             picked.month,
//             picked.day,
//             time.hour,
//             time.minute,
//           );
//         });
//       }
//     }
//   }

//   Future<void> uploadAllActiveCalls(BuildContext context, String billCount) async {
//   final activeCalls = _callLogs.where((log) => (log.duration ?? 0) > 0).toList();
//   if (activeCalls.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         backgroundColor: Colors.red,
//         content: Text('No active calls to upload.'),
//       ),
//     );
//     return;
//   }
//   for (var log in activeCalls) {
//     uploadcalllog(context, log, billCount, showSnackbar: false);
//   }
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(
//       backgroundColor: Color.fromARGB(255, 49, 212, 4),
//       content: Text('All active calls uploaded!'),
//     ),
//   );
//   setState(() {
//     _startTime = null;
//     _endTime = null;
//   });
//   await _fetchCallLogs();
// }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
     
//       ),
//       body: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               ElevatedButton(
//                 onPressed: () => _selectStartTime(context),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.indigo,
//                   foregroundColor: Colors.white,
//                   padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                   elevation: 4,
//                 ),
//                 child: Text(
//                   _startTime == null
//                       ? 'Select Start Time'
//                       : DateFormat('yyyy-MM-dd\nHH:mm').format(_startTime!),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//               ElevatedButton(
//                 onPressed: () => _selectEndTime(context),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.teal,
//                   foregroundColor: Colors.white,
//                   padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                   elevation: 4,
//                 ),
//                 child: Text(
//                   _endTime == null
//                       ? 'Select End Time'
//                       : DateFormat('yyyy-MM-dd\nHH:mm').format(_endTime!),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 12),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ElevatedButton.icon(
//                 onPressed: (_startTime != null && _endTime != null)
//                     ? _fetchCallLogs
//                     : null,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.deepOrange,
//                   foregroundColor: Colors.white,
//                   padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                   elevation: 5,
//                 ),
//                 icon: Icon(Icons.download_rounded),
//                 label: Text('Fetch Logs'),
//               ),
//             ],
//           ),
//           if (_logsByHour.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//               child: Container(
//                 padding: EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.lightBlue.shade50,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.lightBlueAccent),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     _buildSummaryColumn('Total Calls', '$_totalCalls'),
//                     _buildSummaryColumn('Active Calls', '$_totalActiveCalls'),
//                     _buildSummaryColumn('Total Duration', '${_totalDuration}s'),
//                   ],
//                 ),
//               ),
//             ),
//           Expanded(
//             child: _logsByHour.isNotEmpty
//                 ? ListView(
//                     padding: EdgeInsets.all(10),
//                     children: _logsByHour.entries.map((entry) {
                  
//                       return Card(
//                         elevation: 4,
//                         margin: EdgeInsets.symmetric(vertical: 8),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(15),
//                         ),
//                         child: ExpansionTile(
//                           title: Text(
//                             'Hour: ${entry.key}',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                               color: Colors.indigo,
//                             ),
//                           ),
//                           children: entry.value.map((log) {
//                             return Container(
//                               margin:
//                                   EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                               padding: EdgeInsets.all(10),
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[100],
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Icon(Icons.call, color: Colors.green),
//                                   SizedBox(width: 10),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           'Name: ${log.name ?? "Unknown"}',
//                                           style: TextStyle(
//                                             fontSize: 14,
//                                             fontWeight: FontWeight.w600,
//                                           ),
//                                         ),
//                                         Text(
//                                           'Number: ${log.number}',
//                                           style: TextStyle(
//                                             fontSize: 13,
//                                             color: Colors.grey[700],
//                                           ),
//                                         ),
//                                         Text(
//                                           'Duration: ${log.duration} seconds',
//                                           style: TextStyle(
//                                             fontSize: 13,
//                                             color: Colors.grey[600],
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           }).toList(),
//                         ),
//                       );
//                     }).toList(),
//                   )
//                 : Center(
//                     child: Text(
//                       'No call logs found.',
//                       style: TextStyle(fontSize: 16, color: Colors.grey),
//                     ),
//                   ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SizedBox(
//           width: double.infinity,
//           height: 50,
//           child: ElevatedButton(
//             onPressed: () {
//               // TODO: Add your action here
//               if (_callLogs.isNotEmpty) {
//                 showDialog(
//   context: context,
//   builder: (context) {
//     return AlertDialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(20),
//       ),
//       title: Row(
//         children: [
//           Icon(Icons.note_add, color: Colors.deepPurple),
//           SizedBox(width: 10),
//           Text('Total Bill Count'),
//         ],
//       ),
//       content: TextField(
//         controller: _dialogController,
//         maxLines: 1,
//         decoration: InputDecoration(
//           hintText: 'Total Bill Count',
//           filled: true,
//           fillColor: Colors.grey[100],
//           contentPadding: EdgeInsets.all(12),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide.none,
//           ),
//         ),
//       ),
//       actionsPadding: EdgeInsets.only(right: 10, bottom: 10),
//       actions: [
//         TextButton(
//           onPressed: () {
//             Navigator.of(context).pop();
//             _dialogController.clear();
//           },
//           style: TextButton.styleFrom(
//             foregroundColor: Colors.grey[700],
//           ),
//           child: Text('Cancel'),
//         ),
//         ElevatedButton.icon(
//           onPressed: () {
//             final billCount = _dialogController.text;
//             Navigator.of(context).pop();
//             _dialogController.clear();
//             uploadAllActiveCalls(this.context, billCount);
//           },
//           icon: Icon(Icons.cloud_upload),
//           label: Text('Upload'),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.deepPurple,
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           ),
//         ),
//       ],
//     );
//   },
// );

//               } else {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     backgroundColor: Colors.red,
//                     content: Text('No call logs to upload.'),
//                   ),
//                 );
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blueAccent,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: Text(
//               'Upload Call Log',
//               style: TextStyle(fontSize: 18),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// Widget _buildSummaryColumn(String title, String value) {
//   return Column(
//     children: [
//       Text(
//         title,
//         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//       ),
//       SizedBox(height: 5),
//       Text(
//         value,
//         style: TextStyle(fontSize: 16, color: Colors.blueAccent),
//       ),
//     ],
//   );
// }
