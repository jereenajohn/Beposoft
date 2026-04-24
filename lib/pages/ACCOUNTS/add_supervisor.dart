
import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/update_supervisor.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:beposoft/pages/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class add_supervisor extends StatefulWidget {
  const add_supervisor({super.key});

  @override
  State<add_supervisor> createState() => _add_supervisorState();
}

class _add_supervisorState extends State<add_supervisor> {
 @override
  void initState() {
    super.initState();
    getdepartments();
    getmanegers();
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

var url = "$api/api/add/department/";


  TextEditingController name = TextEditingController();
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
            'department_name':productData['department'],
            
          });
        
        }
        setState(() {
          manager = managerlist;
                  

          
        });
      }
    } catch (error) {
      
    }
  }
  
  void addsupervisor(String name, BuildContext context) async {
    
        

          final token = await gettokenFromPrefs();

    try {
      var response = await http.post(
        Uri.parse("$api/api/add/supervisor/"),
        headers: {
          'Authorization': 'Bearer $token',
          
        },
        body: {
          "name": name,
          "department":selectedDepartmentId.toString(),

        },
      );

      

      if (response.statusCode == 201) {
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
 Future<void> deletesupervisor(int Id) async {
    final token = await gettokenFromPrefs();

    try {
      final response = await http.delete(
        Uri.parse('$api/api/supervisor/update/$Id/'),
        headers: {
          'Authorization': ' Bearer $token',
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
 int? selectedDepartmentId; // Variable to store the selected department's ID
  String? selectedDepartmentName; // Variable to store the selected department's name
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
  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(


      backgroundColor: Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(
           title: Text(
          "Add supervisor",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Custom back arrow
          onPressed: () async {
            final dep = await getdepFromPrefs();
            if (dep == "BDO") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        bdo_dashbord()), // Replace AnotherPage with your target page
              );
            }  else if (dep == "BDM") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        bdm_dashbord()), // Replace AnotherPage with your target page
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


            else if (dep == "ADMIN") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        admin_dashboard()), // Replace AnotherPage with your target page
              );
            }
            
            
            else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        dashboard()), // Replace AnotherPage with your target page
              );
            }
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
            SizedBox(height: 15),
           
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
                      "Add Supervisor",
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
                  controller: name,
                  decoration: InputDecoration(
                    labelText: 'name',
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
                  value: selectedDepartmentId,
                  hint: Text('Select a department'),
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
                    addsupervisor(name.text, context);
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
                  "Available Supervisors",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
     ],
   ),
 ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 15,left: 15,bottom: 55),
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
                          child: Text("${manager[i]['name']}(${manager[i]['department_name']})"),
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