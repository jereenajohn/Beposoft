import 'dart:convert'; // Add this import for jsonDecode
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class counterModel extends ChangeNotifier {
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> get departments => _departments;

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchDepartments() async {
    final token = await gettokenFromPrefs();
     String url = "$api/api/departments/";

    try {
      var response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded['data'];
        _departments = data.cast<Map<String, dynamic>>();
        notifyListeners();
      }
    } catch (e) {
    
    
    }
  }

  Future<void> adddepartment(String department, BuildContext context) async {
    final token = await gettokenFromPrefs();
     String url = "$api/api/add/department/";

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {"name": department},
      );
      if (response.statusCode == 201) {
        await fetchDepartments(); // Refresh the list after adding
        // Navigator.pop(context); // Remove or comment out this line
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color.fromARGB(255, 49, 212, 4),
            content: Text('Success'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('An error occurred. Please try again.'),
        ),
      );
    }
  }
}
