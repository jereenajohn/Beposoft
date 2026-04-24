import 'dart:convert';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AttendanceSheet extends StatefulWidget {
  const AttendanceSheet({super.key});

  @override
  State<AttendanceSheet> createState() => _AttendanceSheetState();
}

class _AttendanceSheetState extends State<AttendanceSheet> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredStaffList = [];
  List<Map<String, dynamic>> staffList = [];
  List<String> attendanceStatuses = ['Present', 'Absent', 'Half Day Leave'];

  @override
  void initState() {
    super.initState();
    getstaff();
    searchController.addListener(_filterStaffList);
  }

  void _filterStaffList() {
    String query = searchController.text;
    setState(() {
      if (query.isEmpty) {
        filteredStaffList = List.from(staffList);
      } else {
        filteredStaffList = staffList
            .where((staff) =>
                staff['name'].toLowerCase().contains(query.toLowerCase()))
            .toList(); // Filter based on query
      }
    });
  }

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> getstaff() async {
    try {
      final token = await gettokenFromPrefs();
      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      var response = await http.get(
        Uri.parse('$api/api/get/staff/attendance/$currentDate/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        List<Map<String, dynamic>> fetchedStaffList = [];
        for (var productData in productsData) {
          fetchedStaffList.add({
            'id': productData['staff_id'],
            'name': productData['staff_name'],
            'designation': productData['staff_designation'],
            'attendanceStatus': productData['status'],
          });
        }
        setState(() {
          staffList = fetchedStaffList;
          filteredStaffList =
              fetchedStaffList; // Set filteredStaffList with the fetched data
        });
      }
    } catch (error) {
      // Handle the error here
    }
  }

  Future<void> updateattendance(int staffId, String newStatus) async {
    try {
      final token = await gettokenFromPrefs();
      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      var response = await http.put(
        Uri.parse('$api/api/attendance/status/update/$staffId/$currentDate/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
          {
            'attendance_status': newStatus,
          },
        ),
      );

      
            


    if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        getstaff();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update attendance'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating attendance'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance Sheet',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
      body: Column(
        children: [
          // Search Bar placed outside of AppBar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search Staff...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(
                    color: Colors.blue, // Set your desired border color here
                    width: 2.0, // Set the border width
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(
                    color: Colors
                        .blue, // Border color when TextField is not focused
                    width: 2.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(
                    color: Colors
                        .blueAccent, // Border color when TextField is focused
                    width: 2.0,
                  ),
                ),
              ),
              onChanged: (query) {
                _filterStaffList(); // Call the function without passing parameters
              },
            ),
          ),
          // Staff List
          filteredStaffList.isEmpty
              ? Center(child: CircularProgressIndicator())
              : Expanded(
                  child: ListView.builder(
                    itemCount: filteredStaffList.length,
                    itemBuilder: (context, index) {
                      final staff = filteredStaffList[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.blueAccent,
                                  child: Text(
                                    staff['name'][0].toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        staff['name'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        staff['designation'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.blueAccent,
                                                width: 1),
                                          ),
                                          child: DropdownButton<String>(
                                            value: staff[
                                                'attendanceStatus'], // Bind the value to the current status of the staff
                                            underline: SizedBox(),
                                            isExpanded: true,
                                            icon: Icon(Icons.arrow_drop_down,
                                                color: Colors.blueAccent),
                                            items: attendanceStatuses
                                                .map((String status) {
                                              return DropdownMenuItem<String>(
                                                value: status,
                                                child: Text(
                                                  status,
                                                  style:
                                                      TextStyle(fontSize: 16),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (newStatus) {
                                              if (newStatus != null) {
                                                setState(() {
                                                  filteredStaffList[index]
                                                          ['attendanceStatus'] =
                                                      newStatus; // Update the attendance status in filteredStaffList
                                                });
                                                updateattendance(staff['id'],
                                                    newStatus); // Update attendance in the backend
                                              }
                                            },
                                          )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
