import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:beposoft/pages/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class update_attribute extends StatefulWidget {
  var id;
  var value;
  update_attribute({super.key,required this.id,required this.value});

  @override
  State<update_attribute> createState() => _update_attributeState();
}

class _update_attributeState extends State<update_attribute> {
  List<Map<String, dynamic>> attributes = [];
  List<Map<String, dynamic>> valuess = [];

  String? selectedAttribute;
  var selectedAttributeId;
  var idvalue;

  @override
  void initState() {
    super.initState();
    getattribute();
    values.text = widget.value['value'];
    selectedAttributeId = widget.value['attribute'];

  }

  TextEditingController attribute = TextEditingController();
  TextEditingController values = TextEditingController();
  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
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
  void updateattribute(String attributeName, BuildContext context) async {
    var attributeUpperCase = attributeName.toUpperCase();
    

    final token = await gettokenFromPrefs();

    // Fetch the existing attributes
    List<Map<String, dynamic>> existingAttributes = await getattribute();

    // Check if the attribute already exists
    bool attributeExists = existingAttributes
        .any((attr) => attr['name'].toUpperCase() == attributeUpperCase);

    if (attributeExists) {
      // Show SnackBar if it already exists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Attribute already exists.'),
        ),
      );
      return; // Exit the function
    }

    // Proceed with adding the attribute
    try {
      var response = await http.put(
        Uri.parse('$api/api/product/attribute/${widget.id}/delete/'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "name": attributeUpperCase // Encode the body as JSON
        }),
      );

      

      if (response.statusCode == 200) {
        

        // Navigate or perform other actions upon successful response
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => update_attribute()),
        // );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color.fromARGB(255, 49, 212, 4),
            content: Text('Attribute added successfully'),
          ),
        );
        getattribute();
      } else {
       
      
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to add attribute. Please try again.'),
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

  Future<List<Map<String, dynamic>>> getattribute() async {

    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/product/attributes/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> attributelist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        for (var productData in parsed) {
          attributelist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }
         for (var productData in parsed) {
          if (productData['id'] == widget.id) {
            attribute.text = productData['name'];
          }
        }

        setState(() {
          attributes = attributelist;
          // Set selectedAttribute for the dropdown
          final found = attributelist.firstWhere(
            (attr) => attr['id'] == selectedAttributeId,
            orElse: () => {},
          );
          selectedAttribute = found.isNotEmpty ? found['name'] : null;
        });
getSelectedAttributeName();
        return attributelist; // Return the list of attributes
      } else {
        throw Exception("Failed to load attributes");
      }
    } catch (error) {
      
      return []; // Return an empty list in case of error
    }
  }

  Future<void> deleteattributes(int attributeId, BuildContext context) async {
    final token = await gettokenFromPrefs();

    try {
      final response = await http.delete(
        Uri.parse('$api/api/product/attribute/$attributeId/delete/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color.fromARGB(255, 49, 212, 4),
            content: Text('Deleted successfully'),
          ),
        );

        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => update_attribute()),
        // );
      } else {
        throw Exception('Failed to delete attribute ID: $attributeId');
      }
    } catch (error) {
      // Handle any errors and show a failure message
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to delete attribute. Please try again.'),
        ),
      );
    }
  }

  void removeProduct(int index) {
    setState(() {
      attributes.removeAt(index);
    });
  }
Future<void> updatevalues(String value, int? attributeId) async {
  if (attributeId == null || value.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please select an attribute and enter a value.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final token = await gettokenFromPrefs();

  // Step 1: Fetch existing values for the selected attribute
  try {
    var response = await http.get(
      Uri.parse('$api/api/product/attribute/$attributeId/values/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<Map<String, dynamic>> existingValues = [];
      final parsed = jsonDecode(response.body);

      for (var valueData in parsed) {
        existingValues.add({
          'id': valueData['id'],
          'value': valueData['value'],
          'attribute': valueData['attribute'],
        });
      }

      // Step 2: Check if the entered value already exists
      bool valueExists = existingValues.any((existingValue) => 
          existingValue['value'].toString().toLowerCase() == value.toLowerCase());

      if (valueExists) {
        // If the value already exists, show a SnackBar and stop the function
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This value already exists for the selected attribute.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Step 3: If value does not exist, proceed to add the new value
      var addResponse = await http.put(
        Uri.parse('$api/api/product/attribute/${widget.value['id']}/update/'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "attribute": selectedAttributeId, // Send the selected attribute ID
          "value": value, // Send the entered value
        }),
      );

      if (addResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attribute value added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => add_attribute()),
        );
      } else {
      
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add attribute value.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      throw Exception("Failed to fetch existing values for attribute $attributeId");
    }
  } catch (error) {
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('An error occurred. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  Future<void> getvalues(int attributeId) async {
    final token = await gettokenFromPrefs();

    try {
      // Fetch values for the selected attribute ID
      var response = await http.get(
        Uri.parse('$api/api/product/attribute/$attributeId/values/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> valuesList = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        

        // Iterate through the fetched data and only include values with the correct attribute ID
        for (var valueData in parsed) {
          if (valueData['attribute'] == attributeId) {
            valuesList.add({
              'id': valueData['id'],
              'value': valueData['value'],
              'attribute': valueData['attribute'],
            });
          }
        }

        // Update the state with the fetched values
        setState(() {
          valuess = valuesList;
          
        });
      } else {
        throw Exception("Failed to load values for attribute $attributeId");
      }
    } catch (error) {
      
    }
  }

  drower d = drower();
  Widget _buildDropdownTile(
      BuildContext context, String title, List<String> options) {
    return ExpansionTile(
      title: Text(title),
      children: options.map((option) {
        return ListTile(
          title: Text(option),
          onTap: () {
            Navigator.pop(context);
            d.navigateToSelectedPage(
                context, option); // Navigate to selected page
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

  String? getSelectedAttributeName() {
  final found = attributes.firstWhere(
    (attr) => attr['id'] == selectedAttributeId,
    orElse: () => {},
  );
  return found.isNotEmpty ? found['name'] : null;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromARGB(242, 255, 255, 255),
        appBar: AppBar(
             title: Text(
          "Add Attribute",
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
              onPressed: () {},
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
                          border: Border.all(
                              color: Color.fromARGB(255, 202, 202, 202)),
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
                                  border: Border.all(
                                      color:
                                          Color.fromARGB(255, 202, 202, 202)),
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(height: 10),
                                    Text(
                                      "New Attributes",
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
                                "Attributes",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                width: constraints.maxWidth * 0.9,
                                child: TextField(
                                  controller: attribute,
                                  decoration: InputDecoration(
                                    labelText: 'Enter Attribute',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8.0),
                                  ),
                                ),
                              ),
                              SizedBox(height: 15),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    updateattribute(attribute.text, context);
                                  });
                                },
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                    Colors.blue,
                                  ),
                                  shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  fixedSize: MaterialStateProperty.all<Size>(
                                    Size(constraints.maxWidth * 0.4, 50),
                                  ),
                                ),
                                child: Text("Submit",
                                    style: TextStyle(color: Colors.white)),
                              ),

                              // Displaying the list of departments as a table
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                              color: Color.fromARGB(255, 202, 202, 202)),
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
                                  border: Border.all(
                                      color:
                                          Color.fromARGB(255, 202, 202, 202)),
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(height: 10),
                                    Text(
                                      "Add Attributes Values",
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
                                "Select Attribute",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),

                              // Dropdown to select an attribute
                              Container(
                                width: constraints.maxWidth * 0.9,
                                padding: EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: Text("Select Attribute"),
                                  value: selectedAttribute,
                                    underline: SizedBox.shrink(),
                                  items: attributes.map((attr) {
                                    return DropdownMenuItem<String>(
                                      value: attr['name'],
                                      child: Text(attr['name']),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedAttribute = value;
                                      final found = attributes.firstWhere(
                                        (attr) => attr['name'] == value,
                                        orElse: () => {},
                                      );
                                      if (found.isNotEmpty && found['id'] != null) {
                                        selectedAttributeId = found['id'];

                                        getvalues(selectedAttributeId!);
                                      } else {
                                        selectedAttributeId = null;
                                      }
                                    });
                                  },
                                ),
                              ),
                              Text(
                                "Values",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                width: constraints.maxWidth * 0.9,
                                child: TextField(
                                  controller: values,
                                  decoration: InputDecoration(
                                    labelText: 'Enter Value',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8.0),
                                  ),
                                ),
                              ),
                              SizedBox(height: 15),
                              ElevatedButton(
                                onPressed: () {
                                  updatevalues(values.text, selectedAttributeId);
//  Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => update_attribute()),
//         );                               
        
         },
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                    Colors.blue,
                                  ),
                                  shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  fixedSize: MaterialStateProperty.all<Size>(
                                    Size(constraints.maxWidth * 0.4, 50),
                                  ),
                                ),
                                child: Text("Submit",
                                    style: TextStyle(color: Colors.white)),
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
                            "Available Attributes",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(right: 15, left: 15,bottom: 55),
                      child: Container(
                        color: Colors.white,
                        child: Table(
                          border: TableBorder.all(
                              color: Color.fromARGB(255, 214, 213, 213)),
                          columnWidths: {
                            0: FixedColumnWidth(
                                40.0), // Fixed width for the first column (No.)
                            1: FlexColumnWidth(
                                2), // Flex width for the second column (Department Name)
                            // 2: FixedColumnWidth(
                            //     50.0), // Fixed width for the third column (Edit)
                            3: FixedColumnWidth(
                                50.0), // Fixed width for the fourth column (Delete)
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
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold, color: Colors.white,),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    "Attribute Name",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    "Values",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                // Padding(
                                //   padding: EdgeInsets.all(8.0),
                                //   child: Text(
                                //     "Edit",
                                //     style:
                                //         TextStyle(fontWeight: FontWeight.bold),
                                //   ),
                                // ),
                                
                              ],
                            ),
                            for (int i = 0; i < attributes.length; i++)
                              TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text((i + 1).toString()),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      // Navigate to the update attribute page with the selected attribute ID
                                      // Navigator.push(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //     builder: (context) =>
                                      //         update_attribute(), // Replace with your update page
                                      //   ),
                                      // );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(attributes[i]['name']),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: GestureDetector(
                                      onTap: () async {
                                        // Call the function to fetch values for the selected attribute
                                        await getvalues(attributes[i]['id']);

                                        // If no values are found, show a SnackBar
                                        if (valuess.isEmpty ||
                                            valuess[0]['attribute'] !=
                                                attributes[i]['id']) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'No values to display for this attribute.'),
                                              backgroundColor: Colors
                                                  .red, // You can customize the color
                                            ),
                                          );
                                        }
                                      },
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Check if there are any values for this attribute and display them
                                          valuess.isNotEmpty &&
                                                  valuess[0]['attribute'] ==
                                                      attributes[i]['id']
                                              ? Column(
                                                  children:
                                                      valuess.map((value) {
                                                    return GestureDetector(
                                                      onTap: () {
                                                       
                                                            //selectedAttribute = value['value'];
                                                        selectedAttributeId = value['id'];
                                                        values.text = value['value'];
                                                      },
                                                      child: Padding(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            vertical: 4.0),
                                                        child:
                                                            Text(value['value']),
                                                      ),
                                                    );
                                                  }).toList(),
                                                )
                                              : Image.asset(
                                                  "lib/assets/view.jpeg",
                                                  width: 20,
                                                  height: 20,
                                                ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Padding(
                                  //   padding: const EdgeInsets.all(8.0),
                                  //   child: GestureDetector(
                                  //     onTap: () {
                                  //       // Call the function to fetch values for the selected attribute
                                  //       getvalues(attributes[i]['id']);
                                  //     },
                                  //     child: Image.asset(
                                  //       "lib/assets/view.png",
                                  //       width: 20,
                                  //       height: 20,
                                  //     ),
                                  //   ),
                                  // ),
                                  
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
        ));
  }

 
}
