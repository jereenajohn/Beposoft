
import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/update_state.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:beposoft/pages/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class add_state extends StatefulWidget {
  const add_state({super.key});

  @override
  State<add_state> createState() => _add_stateState();
}

class _add_stateState extends State<add_state> {
 @override
  void initState() {
    super.initState();
    getstate();
  }

var url = "$api/api/add/department/";


  TextEditingController state = TextEditingController();
    TextEditingController province = TextEditingController();

Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
var departments;

  List<Map<String, dynamic>> stat = [];

    Future<void> getstate() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
        
        List<Map<String, dynamic>> statelist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        
 for (var productData in productsData) {
          String imageUrl = "${productData['image']}";
          statelist.add({
            'id': productData['id'],
            'name': productData['name'],
            
          });
        
        }
        setState(() {
          stat = statelist;
                  

          
        });
      }
    } catch (error) {
      
    }
  }
  
  void addstate(String state, String province, BuildContext context) async {
    

          final token = await gettokenFromPrefs();

    try {
      var response = await http.post(
        Uri.parse('$api/api/add/state/'),
        headers: {
          'Authorization': 'Bearer $token',
          
        },
        body: {
          "name": state,
          "province": province,
          
          },
      );

      
            


      if (response.statusCode == 201) {
        var responseData = jsonDecode(response.body);

     Navigator.push(context, MaterialPageRoute(builder: (context)=>add_state()));
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
 Future<void> deletestate(int Id) async {
    final token = await gettokenFromPrefs();

    try {
      final response = await http.delete(
        Uri.parse('$api/api/state/update/$Id/'),
        headers: {
          'Authorization': '$token',
        },
      );
    
    if(response.statusCode == 200){
         ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color.fromARGB(255, 49, 212, 4),
          content: Text('Deleted sucessfully'),
        ),
      );
         Navigator.push(context, MaterialPageRoute(builder: (context)=>add_state()));
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
      stat.removeAt(index);
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
          "Add state",
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
    width: constraints.maxWidth * 0.9,
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: constraints.maxWidth * 0.9,
            decoration: BoxDecoration(
              color:const Color.fromARGB(255, 2, 65, 96),
              border: Border.all(color: Color.fromARGB(255, 202, 202, 202)),
            ),
            child: Column(
              children: [
                SizedBox(height: 10),
                Text(
                  "New State",
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
            "State",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Container(
            width: constraints.maxWidth * 0.9,
            child: TextField(
              controller: state,
              decoration: InputDecoration(
                labelText: 'State',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 8.0),
              ),
            ),
          ),
          SizedBox(height: 5),

            Text(
            "Province",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Container(
            width: constraints.maxWidth * 0.9,
            child: TextField(
              controller: province,
              decoration: InputDecoration(
                labelText: 'Province',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 8.0),
              ),
            ),
          ),
          SizedBox(height: 5,),
          ElevatedButton(
            onPressed: () {
              setState(() {
                addstate(state.text,province.text, context);
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
                Size(constraints.maxWidth * 0.4, 50),
              ),
            ),
            child: Text("Submit", style: TextStyle(color: Colors.white)),
          ),
         
          // Displaying the list of departments as a table
          SizedBox(height: 10),

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
                  "Available States",
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
                          "Department Name",
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
                  for (int i = 0; i < stat.length; i++)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text((i + 1).toString()),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(stat[i]['name']),
                        ),
                                     Padding(
                                       padding: const EdgeInsets.all(8.0),
                                       child: GestureDetector(
                                            onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context)=>update_state(id:stat[i]['id'])));
                                       
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