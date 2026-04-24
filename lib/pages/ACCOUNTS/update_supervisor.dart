
import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_family.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/update_department.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:flutter/material.dart';

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


class update_supervisor extends StatefulWidget {
  final id;
  const update_supervisor({super.key ,required this.id});

  @override
  State<update_supervisor> createState() => _update_supervisorState();
}

class _update_supervisorState extends State<update_supervisor> {
 @override
  void initState() {
    super.initState();
    getdepartments();
    getmanegers();
  }

var url = "$api/api/add/department/";

 int? selectedDepartmentId; // Variable to store the selected department's ID
String? selectedDepartmentName; // Variable to store the selected department's name

Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
var departments;
  List<Map<String, dynamic>> dep = [];
   List<Map<String, dynamic>> manager = [];

    Future<void> getdepartments() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/departments/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
        
        List<Map<String, dynamic>> departmentlist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        
 for (var productData in productsData) {
          String imageUrl = "${productData['image']}";
          departmentlist.add({
            'id': productData['id'],
            'name': productData['name'],
            
          });
        
        }
        setState(() {
          dep = departmentlist;
                  

          
        });
      }
    } catch (error) {
      
    }
  }
  
  TextEditingController namehint = TextEditingController();
    TextEditingController dephint = TextEditingController();
var depp;

    Future<void> getmanegers() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/supervisors/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
        
        List<Map<String, dynamic>> managerlist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

 for (var productData in productsData) {
          String imageUrl = "${productData['image']}";
          managerlist.add({
            'id': productData['id'],
            'name': productData['name'],
            'department_name':productData['department_name'],
            'department':productData['department']
            
          });

            if(widget.id==productData['id']){
              
              
          namehint.text=productData['name']?? '';;
        selectedDepartmentName=productData['department'];
        
              
        }
        
        }
        setState(() {
          manager = managerlist;
                  

          
        });
      }
    } catch (error) {
      
    }
  }
  
  void updatesupervisor(String name, BuildContext context) async {
    
        
                


          final token = await gettokenFromPrefs();

    try {
      var response = await http.put(
        Uri.parse("$api/api/supervisor/update/${widget.id}/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "name": name,
          "department":selectedDepartmentId.toString(),

        }),
      );

      

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);

     Navigator.push(context, MaterialPageRoute(builder: (context)=>add_supervisor()));
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color.fromARGB(255, 49, 212, 4),
          content: Text('sucess'),
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
 Future<void> deletedepartment(int Id) async {
    final token = await gettokenFromPrefs();

    try {
      final response = await http.delete(
        Uri.parse('$api/api/supervisor/update/$Id/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
    
    if(response.statusCode == 200){
         ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color.fromARGB(255, 49, 212, 4),
          content: Text('Deleted sucessfully'),
        ),
      );
         Navigator.push(context, MaterialPageRoute(builder: (context)=>add_supervisor()));
    }

      if (response.statusCode == 204) {
      } else {
        throw Exception('Failed to delete wishlist ID: $Id');
      }
    } catch (error) {
    }
  }

  void removeProduct(int index) {
    setState(() {
      manager.removeAt(index);
    });
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

  //searchable dropdown

 

  String? selectedValue;
  final TextEditingController textEditingController = TextEditingController();

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }
  void logout() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('userId');
  await prefs.remove('token');

  // Use a post-frame callback to show the SnackBar after the current frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (ScaffoldMessenger.of(context).mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged out successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  });

  // Wait for the SnackBar to disappear before navigating
  await Future.delayed(Duration(seconds: 2));

  // Navigate to the HomePage after the snackbar is shown
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => login()),
  );
}

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(


      backgroundColor: Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(
         
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
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
           SizedBox(height: 20,),
           Padding(
      padding: EdgeInsets.symmetric(horizontal: 1),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: Color.fromARGB(255, 202, 202, 202)),
        ),
        width: MediaQuery.of(context).size.width * 0.9,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  color:const Color.fromARGB(255, 2, 65, 96),
                  border: Border.all(color: Color.fromARGB(255, 202, 202, 202)),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    Text(
                      "Update Supervisor",
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
              Text(
                "Name",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: TextField(
                  controller: namehint,
                  decoration: InputDecoration(
                    
                                    hintText: namehint.text.isNotEmpty ? namehint.text : 'Enter your name',

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(10.0),
    border: Border.all(color: Colors.grey),
  ),
  padding: EdgeInsets.symmetric(horizontal: 12),
  child: DropdownButton<int>(
    isExpanded: true,
    value: selectedDepartmentName != null
        ? dep.firstWhere(
            (department) => department['name'] == selectedDepartmentName,
            orElse: () => dep[0],
          )['id']
        : null, // This will handle the default selection
    
    underline: SizedBox(), // Remove the default underline
    onChanged: (int? newValue) {
      setState(() {
        selectedDepartmentId = newValue;
        selectedDepartmentName = dep
            .firstWhere((element) => element['id'] == newValue)['name'];
      });
    },
    items: dep.map<DropdownMenuItem<int>>((department) {
      return DropdownMenuItem<int>(
        value: department['id'],
        child: Text(department['name']),
      );
    }).toList(),
  ),
),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    updatesupervisor(namehint.text, context);
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
                    Size(MediaQuery.of(context).size.width * 0.4, 50),
                  ),
                ),
                child: Text("Submit", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    ),
 SizedBox(height: 15),
 Padding(
   padding: const EdgeInsets.only(left: 15),
   child: Row(
    mainAxisAlignment: MainAxisAlignment.start,
     children: [
       Text(
                  "Available Departments",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
     ],
   ),
 ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 15,left: 15),
            child: Container(
              color: Colors.white,
              child: Table(
                
                border: TableBorder.all(color: Color.fromARGB(255, 214, 213, 213)),
                columnWidths: {
                     0: FixedColumnWidth(40.0), // Fixed width for the first column (No.)
                  1: FlexColumnWidth(2),     // Flex width for the second column (Department Name)
                  2: FixedColumnWidth(50.0), // Fixed width for the third column (Edit)
                  3: FixedColumnWidth(50.0), // Fixed width for the fourth column (Delete)
              
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "No.",
                          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Manager Name",
                          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
                        ),
                      ),
                        Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Edit",
                          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
                        ),
                      ),
                     
                    ],
                  ),
                  for (int i = 0; i < manager.length; i++)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text((i + 1).toString()),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("${manager[i]['name']}(${manager[i]['department']})"),
                        ),
                                     Padding(
                                       padding: const EdgeInsets.all(8.0),
                                       child: GestureDetector(
                                            onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context)=>update_supervisor(id:manager[i]['id'])));
                                       
                                            },
                                            child: Image.asset(
                                                            "lib/assets/edit.jpg",
                                       
                                              width: 20,
                                              height: 20,
                                             
                                            ),
                                          ),
                                     ),
                        
                      ],
                    ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  },
)




    );
  }


  
}