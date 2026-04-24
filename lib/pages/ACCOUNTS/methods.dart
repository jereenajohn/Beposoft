import 'dart:io';


import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class Methods extends StatefulWidget {
  const Methods({super.key});

  @override
  State<Methods> createState() => _MethodsState();
}

class _MethodsState extends State<Methods> {
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

  

int _selectedIndex = 0;

  List<Widget> _forms = [
    Form1(),
    Form2(),
    Form3(),
    Form4(),
     Form5(),
    Form6(),
    Form7(),
   
  ];

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(


      backgroundColor: Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(

        actions: [
            IconButton(
              icon: Image.asset('lib/assets/profile.png'),
               
              onPressed: () {
                
              },
            ),
          ],
          
          ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 110, 110, 110),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        "lib/assets/logo-white.png",
                        width: 100, // Change width to desired size
                        height: 100, // Change height to desired size
                        fit: BoxFit
                            .contain, // Use BoxFit.contain to maintain aspect ratio
                      ),
                      SizedBox(width: 70,),
                      Text(
                        'BepoSoft',
                        style: TextStyle(
                          color: Color.fromARGB(236, 255, 255, 255),
                          fontSize: 20,
                         
                        ),
                      ),
                      
                    ],
                  )),
                  ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>dashboard()));
              },
            ),
                  ListTile(
              leading: Icon(Icons.person),
              title: Text('Customer'),
              onTap: () {
                // Navigator.push(context, MaterialPageRoute(builder: (context)=>customer_list()));
                // Navigate to the Settings page or perform any other action
              },
            ),
             Divider(),
            _buildDropdownTile(context, 'Credit Note', ['Add Credit Note', 'Credit Note List',]),
            _buildDropdownTile(context, 'Recipts', ['Add recipts', 'Recipts List']),
            _buildDropdownTile(context, 'Proforma Invoice', ['New Proforma Invoice', 'Proforma Invoice List',]),
            _buildDropdownTile(context, 'Delivery Note', ['Delivery Note List', 'Daily Goods Movement']),
            _buildDropdownTile(context, 'Orders', ['New Orders', 'Orders List']),
             Divider(),

             Text("Others"),
             Divider(),

            _buildDropdownTile(context, 'Product', ['Product List', 'Stock',]),
            _buildDropdownTile(context, 'Purchase', [' New Purchase', 'Purchase List']),
            _buildDropdownTile(context, 'Expence', ['Add Expence', 'Expence List',]),
            _buildDropdownTile(context, 'Reports', ['Sales Report', 'Credit Sales Report','COD Sales Report','Statewise Sales Report','Expence Report','Delivery Report','Product Sale Report','Stock Report','Damaged Stock']),
            _buildDropdownTile(context, 'GRV', ['Create New GRV', 'GRVs List']),
             _buildDropdownTile(context, 'Banking Module', ['Add Bank ', 'List','Other Transfer']),
               Divider(),




            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Methods'),
              onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (context)=>Methods()));

              },
            ),

            ListTile(
              leading: Icon(Icons.chat),
              title: Text('Chat'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Logout'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Perform logout action
              },
            ),
            
          
          ],
        ),
      ),



        body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
               height: 65,
                child: Row(
                  children: 
                  [
                    ElevatedButton(onPressed: (){
                      setState(() {
                        _selectedIndex = 0;
                      });
                    },
                     style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Color.fromARGB(255, 205, 205, 205), // Text color of the button
                    elevation: 5, // Elevation of the button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)// Rounded corners
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 34), // Padding inside the button
                  ),
                     child: Text("Services")),
                    SizedBox(width:10),
                    ElevatedButton(onPressed: (){
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                     style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Color.fromARGB(255, 205, 205, 205), // Text color of the button
                    elevation: 5, // Elevation of the button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)// Rounded corners
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 34), // Padding inside the button
                  ),
                     child: Text("Ressource")),
                     SizedBox(width:10),
                    ElevatedButton(onPressed: (){
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                     style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Color.fromARGB(255, 205, 205, 205), // Text color of the button
                    elevation: 5, // Elevation of the button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)// Rounded corners
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 34), // Padding inside the button
                  ),
                     child: Text(" Section")),
                     SizedBox(width:10),
                    ElevatedButton(onPressed: (){
                      setState(() {
                        _selectedIndex = 3;
                      });
                    },
                     style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Color.fromARGB(255, 205, 205, 205), // Text color of the button
                    elevation: 5, // Elevation of the button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)// Rounded corners
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 34), // Padding inside the button
                  ),
                     child: Text("location")),
                     SizedBox(width:10),
                    ElevatedButton(onPressed: (){
                      setState(() {
                        _selectedIndex = 4;
                      });
                    }, style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Color.fromARGB(255, 205, 205, 205), // Text color of the button
                    elevation: 5, // Elevation of the button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)// Rounded corners
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 34), // Padding inside the button
                  ),
                     child: Text("Units")),
                     SizedBox(width:10),
                    ElevatedButton(onPressed: (){
                      setState(() {
                        _selectedIndex = 5;
                      });
                    },
                     style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Color.fromARGB(255, 205, 205, 205), // Text color of the button
                    elevation: 5, // Elevation of the button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)// Rounded corners
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 34), // Padding inside the button
                  ),
                     child: Text(" Families")),
                     SizedBox(width:10),
                    ElevatedButton(onPressed: (){
                      setState(() {
                        _selectedIndex = 6;
                      });
                    }, style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Color.fromARGB(255, 205, 205, 205), // Text color of the button
                    elevation: 5, // Elevation of the button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)// Rounded corners
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 34), // Padding inside the button
                  ),
                     child: Text("Tools")),
                    
                  ]
                ),
              ),
            ),
            SizedBox(height: 2,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Swipe for more..",style: TextStyle(color: Colors.grey),),
                SizedBox(width: 8,),
                Icon(Icons.arrow_circle_right_rounded)

              ],
            ),
            
            SizedBox(height: 20),
            _forms[_selectedIndex],
          ],
        ),
      ),
    );
    
  }


 

}






//111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111





class Form1 extends StatefulWidget {
  @override
  State<Form1> createState() => _Form1State();
}

class _Form1State extends State<Form1> {
    List<String>  purchasetype = ["Raw type",'For sale',];
  String selecttype="Raw type";

    List<String>  addedby = ["jeshiya",'nimitha','hanvi','sulfi','yeshitha'];
  String selectaddby="jeshiya";
  double number = 0.00;
    double rate = 0.00;
     double margin = 0.00;


  void incrementNumber() {
    setState(() {
      number += 0.01; // Increment by 0.01 (you can adjust the increment value as needed)
      controller.text = number.toStringAsFixed(2);
      
    });
  }
  void incrementrate() {
    setState(() {
      rate += 0.01; // Increment by 0.01 (you can adjust the increment value as needed)
      controller2.text = rate.toStringAsFixed(2);
      
    });
  }

  void incrementmargin() {
    setState(() {
      margin += 0.01; // Increment by 0.01 (you can adjust the increment value as needed)
      controller3.text = margin.toStringAsFixed(2);
      
    });
  }


  void decrementNumber() {
    setState(() {
      if (number >= 0.01) {
        number -= 0.01; // Decrement by 0.01 (you can adjust the decrement value as needed)
        controller.text = number.toStringAsFixed(2);
         
      }
    });
  }

   void decrementrate() {
    setState(() {
      if (rate >= 0.01) {
        rate -= 0.01; // Decrement by 0.01 (you can adjust the decrement value as needed)
        controller2.text = rate.toStringAsFixed(2);
         
      }
    });
  }
  void decrementmargin() {
    setState(() {
      if (margin >= 0.01) {
        margin -= 0.01; // Decrement by 0.01 (you can adjust the decrement value as needed)
        controller3.text = margin.toStringAsFixed(2);
         
      }
    });
  }
  final TextEditingController controller = TextEditingController();
  final TextEditingController controller2 = TextEditingController();
  final TextEditingController controller3 = TextEditingController();
  var selectedfile;
   @override
  void initState() {
    super.initState();
    controller.text = number.toStringAsFixed(2);

     
    

  }

  Color currentColor = Colors.black;

  void changeColor(Color color) {
    setState(() {
      currentColor = color;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Container(
            child: Column(
              children: [
                SizedBox(height: 15,),


                Text("New Service ",style: TextStyle(fontSize: 20,letterSpacing: 7.0,fontWeight: FontWeight.bold),),

                Padding(
                  padding: const EdgeInsets.only(top: 25,left: 15,right: 15),
                child:Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Color.fromARGB(255, 202, 202, 202)),
                    
                  ),
                  width: 700,

                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                          SizedBox(height: 10,),
                           Text("External ID",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            SizedBox(height: 13,),
                    
                            Container(
                              width: 304,
                              child:  TextField(
                                  decoration: InputDecoration(
                                    labelText: 'External ID',
                                    prefixIcon: Icon(Icons.align_vertical_bottom),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                    
                            ),
                            SizedBox(height: 10,),


                               Text("Sort order:",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),


        Container(
          width: 310,
          height: 49,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
            
              Expanded(
                child: Container(
        
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                     prefixIcon: Icon(Icons.arrow_drop_down_circle),
                    border: InputBorder.none,
                    hintText: '',
                    // Adjust horizontal padding
                  ),
                  onChanged: (value) {
                    setState(() {
                      number = double.tryParse(value) ?? 0.00;
                    });
                  },
                ),
              ),
               Container(
                width: 30,
                color:  Color.fromARGB(255, 88, 184, 248),
                 child: IconButton(
                         icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20,color: Colors.white), // Down arrow icon with size 20
                         onPressed: decrementNumber,
                         
                       ),
               ),
              Container(
                width: 30,
              
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 64, 176, 251),
    border: Border.all(color: Color.fromARGB(255, 64, 176, 251)),
    borderRadius: BorderRadius.only(
      bottomRight: Radius.circular(10),
      topRight: Radius.circular(10)
    )
  ),
                child: IconButton(
                  icon: Icon(Icons.keyboard_arrow_up_rounded, size: 20,color: Colors.white), // Up arrow icon with size 20
                  onPressed: incrementNumber,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),
                       
                        SizedBox(height: 10,),
                           Text("Label",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            SizedBox(height: 13,),
                    
                            Container(
                              width: 304,
                              child:  TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Label',
                                    prefixIcon: Icon(Icons.local_offer),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                    
                            ),

                    
                        SizedBox(height: 10,),
                           Text("Type",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            SizedBox(height: 10,),




              
                          Container(
                    width: 304,
                    height: 49,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 20),
                        Container(
                          width: 276,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '',
                              contentPadding: EdgeInsets.symmetric(horizontal: 1),
                            ),
                            child: DropdownButton<String>(
                              value: selecttype,
                              underline: Container(), // This removes the underline
                              onChanged: (String? newValue) {
                                setState(() {
                                  selecttype = newValue!;
                                  
                                });
                              },
                              items: purchasetype.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              icon: Container(
                                padding: EdgeInsets.only(left: 170), // Adjust padding as needed
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.arrow_drop_down), // Dropdown arrow icon
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  
                               Text("Hourly rate ",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),


        Container(
          width: 310,
          height: 49,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
            
              Expanded(
                child: Container(
        
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  
                  controller: controller2,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                     prefixIcon: Icon(Icons.line_weight),
                    border: InputBorder.none,
                    hintText: '110 €/H',
                    // Adjust horizontal padding
                  ),
                  onChanged: (value) {
                    setState(() {
                      rate = double.tryParse(value) ?? 0.00;
                    });
                  },
                ),
              ),
               Container(
                width: 30,
                color:  Color.fromARGB(255, 88, 184, 248),
                 child: IconButton(
                         icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20,color: Colors.white), // Down arrow icon with size 20
                         onPressed: decrementrate,
                         
                       ),
               ),
              Container(
                width: 30,
              
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 64, 176, 251),
    border: Border.all(color: Color.fromARGB(255, 64, 176, 251)),
    borderRadius: BorderRadius.only(
      bottomRight: Radius.circular(10),
      topRight: Radius.circular(10)
    )
  ),
                child: IconButton(
                  icon: Icon(Icons.keyboard_arrow_up_rounded, size: 20,color: Colors.white), // Up arrow icon with size 20
                  onPressed: incrementrate,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),


                               Text("Margin : ",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),


        Container(
          width: 310,
          height: 49,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
            
              Expanded(
                child: Container(
        
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  
                  controller: controller3,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                     prefixIcon: Icon(Icons.percent),
                    border: InputBorder.none,
                    hintText: '10 %',
                    // Adjust horizontal padding
                  ),
                  onChanged: (value) {
                    setState(() {
                      margin = double.tryParse(value) ?? 0.00;
                    });
                  },
                ),
              ),
               Container(
                width: 30,
                color:  Color.fromARGB(255, 88, 184, 248),
                 child: IconButton(
                         icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20,color: Colors.white), // Down arrow icon with size 20
                         onPressed: decrementmargin,
                         
                       ),
               ),
              Container(
                width: 30,
              
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 64, 176, 251),
    border: Border.all(color: Color.fromARGB(255, 64, 176, 251)),
    borderRadius: BorderRadius.only(
      bottomRight: Radius.circular(10),
      topRight: Radius.circular(10)
    )
  ),
                child: IconButton(
                  icon: Icon(Icons.keyboard_arrow_up_rounded, size: 20,color: Colors.white), // Up arrow icon with size 20
                  onPressed: incrementmargin,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),
SizedBox(height: 15),

   Text("Colors ",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),



Container(
  width: 310,
          height: 49,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              SizedBox(width: 15,),
              Container(
                height: 20,
                width: 169,
                color: currentColor,
              ),
                SizedBox(width: 16,),

             ElevatedButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(''),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: changeColor,
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  },
  child: Text("Select"),
  style: ElevatedButton.styleFrom(
    foregroundColor: Colors.white, backgroundColor: Colors.blue, // Text color of the button
    elevation: 5, // Elevation of the button
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
      
        bottomRight: Radius.circular(10),
        topRight: Radius.circular(10)
      ), // Rounded corners
    ),
    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 34), // Padding inside the button
  ),
)


            ],
          ),
),


SizedBox(height: 15),

   Text("Logo file (peg,png,jpg,gif,svg | max: 10 240 Ko) ",style: TextStyle(fontSize: 13,fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),


Container(
  width: 310,
          height: 49,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              SizedBox(width: 10,),
              Icon(Icons.image),
              SizedBox(width: 5,),
              Container(
                
                width: 145,
               child: Text("Choose file"),
              ),
                SizedBox(width: 16,),

             ElevatedButton(
  onPressed: () {
   imageupload();
  },
  child: Text("Browse"),
  style: ElevatedButton.styleFrom(
    foregroundColor: Colors.white, backgroundColor: const Color.fromARGB(255, 176, 176, 177), // Text color of the button
    elevation: 5, // Elevation of the button
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
      
        bottomRight: Radius.circular(10),
        topRight: Radius.circular(10)
      ), // Rounded corners
    ),
    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30), // Padding inside the button
  ),
)


            ],
          ),
),


                         SizedBox(height: 10,),
                         Text("Technical manager",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),


                          Container(
                    width: 310,
                    height: 49,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 20),
                        Container(
                          width: 276,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '',
                              contentPadding: EdgeInsets.symmetric(horizontal: 1),
                            ),
                            child: DropdownButton<String>(
                              value: selectaddby,
                              underline: Container(), // This removes the underline
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectaddby = newValue!;
                                  
                                });
                              },
                              items: addedby.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              icon: Container(
                                padding: EdgeInsets.only(left: 167), // Adjust padding as needed
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.arrow_drop_down), // Dropdown arrow icon
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                           


                            SizedBox(height: 10,),

                  

         SizedBox(height: 20,),

                 Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 1,
                    width: 300,
                    color: Color.fromARGB(255, 215, 201, 201),
                  ),
                  
                  
                ],
              ),
              

              SizedBox(height: 25,),
             
                
                     
                
                   SizedBox(height: 15,),

                   Row(
                     children:[
                      SizedBox(width: 20,),

                      SizedBox(
                      width: 270,
                       child: ElevatedButton(
                                         onPressed: () {
                        // Your onPressed logic goes here
                                         },
                                         style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Color.fromARGB(255, 64, 176, 251),
                        ),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Set your desired border radius
                          ),
                        ),
                        fixedSize: MaterialStateProperty.all<Size>(
                          Size(95, 15), // Set your desired width and heigh
                        ),
                                         ),
                                         child: Text("Submit",style: TextStyle(color: Colors.white)),
                                       ),
                     ),
                     ] 
                   ),
                SizedBox(height: 20,)


                      ],
                    ),
                  )
                  
  
  
),

                ),

               

              ],
            ),
          );
  }
   void imageupload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() {
          selectedfile = File(result.files.single.path!);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("file selected succesfully"),
          backgroundColor: Color.fromARGB(173, 120, 249, 126),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("error while selecting the file"),
        backgroundColor: Colors.red,
      ));
    }
  }
}

class Form2 extends StatefulWidget {
  @override
  State<Form2> createState() => _Form2State();
}

class _Form2State extends State<Form2> {

   List<String>  masktime = ["No",'Yes',];
  String selectmasktime="No";

   List<String>  section = ["Admin",'Account Manager','Business Development Manager','Business Development Exicutives','logistics Managers','sales Manager'];
  String selectsection="Admin";


    List<String>  services = ["Single Product",'','Varible Product'];
  String selectservices="Single Product";
  double number = 0.00;
    double rate = 0.00;
     double margin = 0.00;


  void incrementNumber() {
    setState(() {
      number += 0.01; // Increment by 0.01 (you can adjust the increment value as needed)
      controller.text = number.toStringAsFixed(2);
      
    });
  }
  void incrementrate() {
    setState(() {
      rate += 0.01; // Increment by 0.01 (you can adjust the increment value as needed)
      controller2.text = rate.toStringAsFixed(2);
      
    });
  }

  void incrementmargin() {
    setState(() {
      margin += 0.01; // Increment by 0.01 (you can adjust the increment value as needed)
      controller3.text = margin.toStringAsFixed(2);
      
    });
  }


  void decrementNumber() {
    setState(() {
      if (number >= 0.01) {
        number -= 0.01; // Decrement by 0.01 (you can adjust the decrement value as needed)
        controller.text = number.toStringAsFixed(2);
         
      }
    });
  }

   void decrementrate() {
    setState(() {
      if (rate >= 0.01) {
        rate -= 0.01; // Decrement by 0.01 (you can adjust the decrement value as needed)
        controller2.text = rate.toStringAsFixed(2);
         
      }
    });
  }
  void decrementmargin() {
    setState(() {
      if (margin >= 0.01) {
        margin -= 0.01; // Decrement by 0.01 (you can adjust the decrement value as needed)
        controller3.text = margin.toStringAsFixed(2);
         
      }
    });
  }
  final TextEditingController controller = TextEditingController();
  final TextEditingController controller2 = TextEditingController();
  final TextEditingController controller3 = TextEditingController();
  var selectedfile2;
   @override
  void initState() {
    super.initState();
    controller.text = number.toStringAsFixed(2);

     
    

  }

  Color currentColor = Colors.black;

  void changeColor(Color color) {
    setState(() {
      currentColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
            child: Column(
              children: [
                SizedBox(height: 15,),


                Text("New Ressource ",style: TextStyle(fontSize: 20,letterSpacing: 7.0,fontWeight: FontWeight.bold),),

                Padding(
                  padding: const EdgeInsets.only(top: 25,left: 15,right: 15),
                child:Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Color.fromARGB(255, 202, 202, 202)),
                    
                  ),
                  width: 700,

                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                          SizedBox(height: 10,),
                           Text("External ID",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            SizedBox(height: 13,),
                    
                            Container(
                              width: 304,
                              child:  TextField(
                                  decoration: InputDecoration(
                                    labelText: 'External ID',
                                    prefixIcon: Icon(Icons.align_vertical_bottom),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                    
                            ),
                            SizedBox(height: 10,),


                               Text("Sort order:",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),


        Container(
          width: 310,
          height: 49,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
            
              Expanded(
                child: Container(
        
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                     prefixIcon: Icon(Icons.arrow_drop_down_circle),
                    border: InputBorder.none,
                    hintText: '',
                    // Adjust horizontal padding
                  ),
                  onChanged: (value) {
                    setState(() {
                      number = double.tryParse(value) ?? 0.00;
                    });
                  },
                ),
              ),
               Container(
                width: 30,
                color:  Color.fromARGB(255, 88, 184, 248),
                 child: IconButton(
                         icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20,color: Colors.white), // Down arrow icon with size 20
                         onPressed: decrementNumber,
                         
                       ),
               ),
              Container(
                width: 30,
              
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 64, 176, 251),
    border: Border.all(color: Color.fromARGB(255, 64, 176, 251)),
    borderRadius: BorderRadius.only(
      bottomRight: Radius.circular(10),
      topRight: Radius.circular(10)
    )
  ),
                child: IconButton(
                  icon: Icon(Icons.keyboard_arrow_up_rounded, size: 20,color: Colors.white), // Up arrow icon with size 20
                  onPressed: incrementNumber,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),
                       
                        SizedBox(height: 10,),
                           Text("Label",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            SizedBox(height: 13,),
                    
                            Container(
                              width: 304,
                              child:  TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Label',
                                    prefixIcon: Icon(Icons.local_offer),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                    
                            ),

                    
                        SizedBox(height: 10,),
                           Text("Mask time ?",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            SizedBox(height: 10,),




              
                          Container(
                    width: 304,
                    height: 49,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 20),
                        Container(
                          width: 276,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '',
                              contentPadding: EdgeInsets.symmetric(horizontal: 1),
                            ),
                            child: DropdownButton<String>(
                              value: selectmasktime,
                              underline: Container(), // This removes the underline
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectmasktime = newValue!;
                                  
                                });
                              },
                              items: masktime.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              icon: Container(
                                padding: EdgeInsets.only(left: 220), // Adjust padding as needed
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.arrow_drop_down), // Dropdown arrow icon
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

SizedBox(height: 10,),
                  
                               Text("Hour capacity by week ",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),


        Container(
          width: 310,
          height: 49,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
            
              Expanded(
                child: Container(
        
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  
                  controller: controller2,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                     prefixIcon: Icon(Icons.line_weight),
                    border: InputBorder.none,
                    hintText: '110 h/week',
                    // Adjust horizontal padding
                  ),
                  onChanged: (value) {
                    setState(() {
                      rate = double.tryParse(value) ?? 0.00;
                    });
                  },
                ),
              ),
               Container(
                width: 30,
                color:  Color.fromARGB(255, 88, 184, 248),
                 child: IconButton(
                         icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20,color: Colors.white), // Down arrow icon with size 20
                         onPressed: decrementrate,
                         
                       ),
               ),
              Container(
                width: 30,
              
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 64, 176, 251),
    border: Border.all(color: Color.fromARGB(255, 64, 176, 251)),
    borderRadius: BorderRadius.only(
      bottomRight: Radius.circular(10),
      topRight: Radius.circular(10)
    )
  ),
                child: IconButton(
                  icon: Icon(Icons.keyboard_arrow_up_rounded, size: 20,color: Colors.white), // Up arrow icon with size 20
                  onPressed: incrementrate,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),


                              
SizedBox(height: 10),

                  
                               Text("Color ",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),

Container(
  width: 310,
          height: 49,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              SizedBox(width: 15,),
              Container(
                height: 20,
                width: 169,
                color: currentColor,
              ),
                SizedBox(width: 16,),

             ElevatedButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(''),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: changeColor,
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  },
  child: Text("Select"),
  style: ElevatedButton.styleFrom(
    foregroundColor: Colors.white, backgroundColor: Colors.blue, // Text color of the button
    elevation: 5, // Elevation of the button
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
      
        bottomRight: Radius.circular(10),
        topRight: Radius.circular(10)
      ), // Rounded corners
    ),
    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 34), // Padding inside the button
  ),
)


            ],
          ),
),


SizedBox(height: 15),
  Text("Logo file (peg,png,jpg,gif,svg | max: 10 240 Ko)",style: TextStyle(fontSize: 12,fontWeight: FontWeight.bold),),
  SizedBox(height: 15),




Container(
  width: 310,
          height: 49,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              SizedBox(width: 10,),
              Icon(Icons.image),
              SizedBox(width: 5,),
              Container(
                
                width: 145,
               child: Text("Choose file"),
              ),
                SizedBox(width: 16,),

             ElevatedButton(
  onPressed: () {
   imageupload2();
  },
  child: Text("Browse"),
  style: ElevatedButton.styleFrom(
    foregroundColor: Colors.white, backgroundColor: const Color.fromARGB(255, 176, 176, 177), // Text color of the button
    elevation: 5, // Elevation of the button
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
      
        bottomRight: Radius.circular(10),
        topRight: Radius.circular(10)
      ), // Rounded corners
    ),
    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30), // Padding inside the button
  ),
)


            ],
          ),
),

 SizedBox(height: 10,),
                           Text("Section",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            SizedBox(height: 10,),




              
                          Container(
                    width: 304,
                    height: 49,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 20),
                        Container(
                          width: 276,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '',
                              contentPadding: EdgeInsets.symmetric(horizontal: 1),
                            ),
                            child: DropdownButton<String>(
                              value: selectsection,
                              underline: Container(), // This removes the underline
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectsection = newValue!;
                                  
                                });
                              },
                              items: section.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              icon: Container(
                                padding: EdgeInsets.only(left: 4), // Adjust padding as needed
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.arrow_drop_down), // Dropdown arrow icon
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),



                         SizedBox(height: 10,),
                         Text("Services",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),


                          Container(
                    width: 310,
                    height: 49,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 20),
                        Container(
                          width: 276,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '',
                              contentPadding: EdgeInsets.symmetric(horizontal: 1),
                            ),
                            child: DropdownButton<String>(
                              value: selectservices,
                              underline: Container(), // This removes the underline
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectservices = newValue!;
                                  
                                });
                              },
                              items: services.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              icon: Container(
                                padding: EdgeInsets.only(left: 137), // Adjust padding as needed
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.arrow_drop_down), // Dropdown arrow icon
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                           


                            SizedBox(height: 10,),

                  

         SizedBox(height: 20,),

                 Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 1,
                    width: 300,
                    color: Color.fromARGB(255, 215, 201, 201),
                  ),
                  
                  
                ],
              ),
              

              SizedBox(height: 25,),
             
                
                     
                
                   SizedBox(height: 15,),

                   Row(
                     children:[
                      SizedBox(width: 20,),

                      SizedBox(
                      width: 270,
                       child: ElevatedButton(
                                         onPressed: () {
                        // Your onPressed logic goes here
                                         },
                                         style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Color.fromARGB(255, 64, 176, 251),
                        ),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Set your desired border radius
                          ),
                        ),
                        fixedSize: MaterialStateProperty.all<Size>(
                          Size(95, 15), // Set your desired width and heigh
                        ),
                                         ),
                                         child: Text("Submit",style: TextStyle(color: Colors.white)),
                                       ),
                     ),
                     ] 
                   ),
                SizedBox(height: 20,)     
                    
                      ],
                    ),
                  )
                  
  
  
),

                ),

               

              ],
            ),
          );
  }

   void imageupload2() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() {
          selectedfile2 = File(result.files.single.path!);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("file selected succesfully"),
          backgroundColor: Color.fromARGB(173, 120, 249, 126),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("error while selecting the file"),
        backgroundColor: Colors.red,
      ));
    }
  }
}


class Form3 extends StatefulWidget {
  @override
  State<Form3> createState() => _Form3State();
}

class _Form3State extends State<Form3> {

   List<String>  purchasetype = ["Raw type",'For sale',];
  String selecttype="Raw type";

    List<String>  user = ["jeshiya",'nimitha','hanvi','sulfi','yeshitha'];
  String selectuser="jeshiya";
  double number = 0.00;
    double rate = 0.00;
     double margin = 0.00;


  void incrementNumber() {
    setState(() {
      number += 0.01; // Increment by 0.01 (you can adjust the increment value as needed)
      controller.text = number.toStringAsFixed(2);
      
    });
  }
  void incrementrate() {
    setState(() {
      rate += 0.01; // Increment by 0.01 (you can adjust the increment value as needed)
      controller2.text = rate.toStringAsFixed(2);
      
    });
  }

  void incrementmargin() {
    setState(() {
      margin += 0.01; // Increment by 0.01 (you can adjust the increment value as needed)
      controller3.text = margin.toStringAsFixed(2);
      
    });
  }


  void decrementNumber() {
    setState(() {
      if (number >= 0.01) {
        number -= 0.01; // Decrement by 0.01 (you can adjust the decrement value as needed)
        controller.text = number.toStringAsFixed(2);
         
      }
    });
  }

   void decrementrate() {
    setState(() {
      if (rate >= 0.01) {
        rate -= 0.01; // Decrement by 0.01 (you can adjust the decrement value as needed)
        controller2.text = rate.toStringAsFixed(2);
         
      }
    });
  }
  void decrementmargin() {
    setState(() {
      if (margin >= 0.01) {
        margin -= 0.01; // Decrement by 0.01 (you can adjust the decrement value as needed)
        controller3.text = margin.toStringAsFixed(2);
         
      }
    });
  }
  final TextEditingController controller = TextEditingController();
  final TextEditingController controller2 = TextEditingController();
  final TextEditingController controller3 = TextEditingController();
  var selectedfile;
   @override
  void initState() {
    super.initState();
   

     
    

  }

  Color currentColor = Colors.black;

  void changeColor(Color color) {
    setState(() {
      currentColor = color;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Container(
            child: Column(
              children: [
                SizedBox(height: 15,),


                Text("New Section ",style: TextStyle(fontSize: 20,letterSpacing: 7.0,fontWeight: FontWeight.bold),),

                Padding(
                  padding: const EdgeInsets.only(top: 25,left: 15,right: 15),
                child:Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Color.fromARGB(255, 202, 202, 202)),
                    
                  ),
                  width: 700,

                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                          
                            SizedBox(height: 10,),


                               Text("Sort order:",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),


        Container(
          width: 310,
          height: 49,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
            
              Expanded(
                child: Container(
        
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                     prefixIcon: Icon(Icons.arrow_drop_down_circle),
                    border: InputBorder.none,
                    hintText: '10',
                    // Adjust horizontal padding
                  ),
                  onChanged: (value) {
                    setState(() {
                      number = double.tryParse(value) ?? 0.00;
                    });
                  },
                ),
              ),
               Container(
                width: 30,
                color:  Color.fromARGB(255, 88, 184, 248),
                 child: IconButton(
                         icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20,color: Colors.white), // Down arrow icon with size 20
                         onPressed: decrementNumber,
                         
                       ),
               ),
              Container(
                width: 30,
              
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 64, 176, 251),
    border: Border.all(color: Color.fromARGB(255, 64, 176, 251)),
    borderRadius: BorderRadius.only(
      bottomRight: Radius.circular(10),
      topRight: Radius.circular(10)
    )
  ),
                child: IconButton(
                  icon: Icon(Icons.keyboard_arrow_up_rounded, size: 20,color: Colors.white), // Up arrow icon with size 20
                  onPressed: incrementNumber,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),
SizedBox(height: 10,),
                           Text("External ID",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            SizedBox(height: 13,),
                    
                            Container(
                              width: 304,
                              child:  TextField(
                                  decoration: InputDecoration(
                                    labelText: 'External ID',
                                    prefixIcon: Icon(Icons.align_vertical_bottom),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                    
                            ),
                       
                        SizedBox(height: 10,),
                           Text("Label",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            SizedBox(height: 13,),
                    
                            Container(
                              width: 304,
                              child:  TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Label',
                                    prefixIcon: Icon(Icons.local_offer),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                    
                            ),

                    
                      
                  
SizedBox(height: 15),
    Text("Color",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
SizedBox(height: 10),

Container(
  width: 310,
          height: 49,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              SizedBox(width: 15,),
              Container(
                height: 20,
                width: 169,
                color: currentColor,
              ),
                SizedBox(width: 16,),

             ElevatedButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(''),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: changeColor,
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  },
  child: Text("Select"),
  style: ElevatedButton.styleFrom(
    foregroundColor: Colors.white, backgroundColor: Colors.blue, // Text color of the button
    elevation: 5, // Elevation of the button
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
      
        bottomRight: Radius.circular(10),
        topRight: Radius.circular(10)
      ), // Rounded corners
    ),
    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 34), // Padding inside the button
  ),
)


            ],
          ),
),




                         SizedBox(height: 10,),
                         Text("User management",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),


                          Container(
                    width: 310,
                    height: 49,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 20),
                        Container(
                          width: 276,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '',
                              contentPadding: EdgeInsets.symmetric(horizontal: 1),
                            ),
                            child: DropdownButton<String>(
                              value: selectuser,
                              underline: Container(), // This removes the underline
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectuser = newValue!;
                                  
                                });
                              },
                              items: user.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              icon: Container(
                                padding: EdgeInsets.only(left: 167), // Adjust padding as needed
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.arrow_drop_down), // Dropdown arrow icon
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                           


                            SizedBox(height: 10,),

                  

         SizedBox(height: 20,),

                 Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 1,
                    width: 300,
                    color: Color.fromARGB(255, 215, 201, 201),
                  ),
                  
                  
                ],
              ),
              

          
             
                
                     
                
                   SizedBox(height: 15,),

                   Row(
                     children:[
                      SizedBox(width: 20,),

                      SizedBox(
                      width: 270,
                       child: ElevatedButton(
                                         onPressed: () {
                        // Your onPressed logic goes here
                                         },
                                         style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Color.fromARGB(255, 64, 176, 251)
                        ),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Set your desired border radius
                          ),
                        ),
                        fixedSize: MaterialStateProperty.all<Size>(
                          Size(95, 15), // Set your desired width and heigh
                        ),
                                         ),
                                         child: Text("Submit",style: TextStyle(color: Colors.white)),
                                       ),
                     ),
                     ] 
                   ),
                SizedBox(height: 20,)


                      ],
                    ),
                  ) 
),

                ),
              ],
            ),
          );
  }
}

class Form4 extends StatefulWidget {
  @override
  State<Form4> createState() => _Form4State();
}

class _Form4State extends State<Form4> {
  List<String>  purchasetype = ["Raw type",'For sale',];
  String selecttype="Raw type";

    List<String>  user = ["",];
  String selectuser="";

 
  var selectedfile;
   @override
  void initState() {
    super.initState();
   

     
    

  }

  Color currentColor = Colors.black;

  void changeColor(Color color) {
    setState(() {
      currentColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
            child: Column(
              children: [
                SizedBox(height: 15,),


                Text("New location ",style: TextStyle(fontSize: 20,letterSpacing: 7.0,fontWeight: FontWeight.bold),),

                Padding(
                  padding: const EdgeInsets.only(top: 25,left: 15,right: 15),
                child:Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Color.fromARGB(255, 202, 202, 202)),
                    
                  ),
                  width: 700,

                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                            SizedBox(height: 10,),

                           Text("External ID",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            SizedBox(height: 13,),
                    
                            Container(
                              width: 304,
                              child:  TextField(
                                  decoration: InputDecoration(
                                    labelText: 'External ID',
                                    prefixIcon: Icon(Icons.align_vertical_bottom),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                    
                            ),
                       
                        SizedBox(height: 10,),
                           Text("Label",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            SizedBox(height: 13,),
                    
                            Container(
                              width: 304,
                              child:  TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Label',
                                    prefixIcon: Icon(Icons.local_offer),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                    
                            ),

                    
                      
                  
SizedBox(height: 15),
    Text("Color",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
SizedBox(height: 10),

Container(
  width: 310,
          height: 49,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              SizedBox(width: 15,),
              Container(
                height: 20,
                width: 169,
                color: currentColor,
              ),
                SizedBox(width: 16,),

             ElevatedButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(''),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: changeColor,
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  },
  child: Text("Select"),
  style: ElevatedButton.styleFrom(
    foregroundColor: Colors.white, backgroundColor: Colors.blue, // Text color of the button
    elevation: 5, // Elevation of the button
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
      
        bottomRight: Radius.circular(10),
        topRight: Radius.circular(10)
      ), // Rounded corners
    ),
    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 34), // Padding inside the button
  ),
)


            ],
          ),
),




                         SizedBox(height: 10,),
                         Text("Ressource",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),


                          Container(
                    width: 310,
                    height: 49,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 20),
                        Container(
                          width: 276,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '',
                              contentPadding: EdgeInsets.symmetric(horizontal: 1),
                            ),
                            child: DropdownButton<String>(
                              value: selectuser,
                              underline: Container(), // This removes the underline
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectuser = newValue!;
                                  
                                });
                              },
                              items: user.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              icon: Container(
                                padding: EdgeInsets.only(left: 167), // Adjust padding as needed
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.arrow_drop_down), // Dropdown arrow icon
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                           


                            SizedBox(height: 10,),

                  

         SizedBox(height: 20,),

                 Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 1,
                    width: 300,
                    color: Color.fromARGB(255, 215, 201, 201),
                  ),
                  
                  
                ],
              ),
              

              SizedBox(height: 25,),
             
                
                     
                
                   SizedBox(height: 15,),

                   Row(
                     children:[
                      SizedBox(width: 20,),

                      SizedBox(
                      width: 270,
                       child: ElevatedButton(
                                         onPressed: () {
                        // Your onPressed logic goes here
                                         },
                                         style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Color.fromARGB(255, 64, 176, 251),
                        ),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Set your desired border radius
                          ),
                        ),
                        fixedSize: MaterialStateProperty.all<Size>(
                          Size(95, 15), // Set your desired width and heigh
                        ),
                                         ),
                                         child: Text("Submit",style: TextStyle(color: Colors.white)),
                                       ),
                     ),
                     ] 
                   ),
                SizedBox(height: 20,)


                      ],
                    ),
                  ) 
),

                ),
              ],
            ),
          );
  }
}
class Form5 extends StatefulWidget {
  @override
  State<Form5> createState() => _Form5State();
}

class _Form5State extends State<Form5> {
 

  List<String>  type = ["Mass","Length","Area","Volume"];
  String selectedtype ="Mass" ;
  String selectuser="";

 
  var selectedfile;
   @override
  void initState() {
  super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
            child: Column(
              children: [
                SizedBox(height: 15,),


                Text("New Units ",style: TextStyle(fontSize: 20,letterSpacing: 7.0,fontWeight: FontWeight.bold),),

                Padding(
                  padding: const EdgeInsets.only(top: 25,left: 15,right: 15),
                child:Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Color.fromARGB(255, 202, 202, 202)),
                    
                  ),
                  width: 700,

                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                            SizedBox(height: 10,),

                           Text("External ID",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            SizedBox(height: 13,),
                    
                            Container(
                              width: 304,
                              child:  TextField(
                                  decoration: InputDecoration(
                                    labelText: 'External ID',
                                    prefixIcon: Icon(Icons.align_vertical_bottom),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                    
                            ),
                       
                        SizedBox(height: 10,),
                           Text("Label",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            SizedBox(height: 13,),
                    
                            Container(
                              width: 304,
                              child:  TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Label',
                                    prefixIcon: Icon(Icons.local_offer),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                    
                            ),

                    
                      
                  



                         SizedBox(height: 10,),
                         Text("Type",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),


                          Container(
                    width: 310,
                    height: 49,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 20),
                        Container(
                          width: 276,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '',
                              contentPadding: EdgeInsets.symmetric(horizontal: 1),
                            ),
                            child: DropdownButton<String>(
                              value: selectedtype,
                              underline: Container(), // This removes the underline
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedtype = newValue!;
                                  
                                });
                              },
                              items: type.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              icon: Container(
                                padding: EdgeInsets.only(left: 167), // Adjust padding as needed
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.arrow_drop_down), // Dropdown arrow icon
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                           


                            SizedBox(height: 10,),

                  

         SizedBox(height: 20,),

                 Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 1,
                    width: 300,
                    color: Color.fromARGB(255, 215, 201, 201),
                  ),
                  
                  
                ],
              ),
              

              SizedBox(height: 25,),
             
                
                     
                
                   SizedBox(height: 15,),

                   Row(
                     children:[
                      SizedBox(width: 20,),

                      SizedBox(
                      width: 270,
                       child: ElevatedButton(
                                         onPressed: () {
                        // Your onPressed logic goes here
                                         },
                                         style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Color.fromARGB(255, 64, 176, 251),
                        ),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Set your desired border radius
                          ),
                        ),
                        fixedSize: MaterialStateProperty.all<Size>(
                          Size(95, 15), // Set your desired width and heigh
                        ),
                                         ),
                                         child: Text("Submit",style: TextStyle(color: Colors.white)),
                                       ),
                     ),
                     ] 
                   ),
                SizedBox(height: 20,)


                      ],
                    ),
                  ) 
),

                ),
              ],
            ),
          );
  }
}

class Form6 extends StatefulWidget {
  @override
  State<Form6> createState() => _Form6State();
}

class _Form6State extends State<Form6> {

   List<String>  services = ["Single Product","Variable",];
  String selectservices="Single Product" ;
  @override
  Widget build(BuildContext context) {
    return Container(
            child: Column(
              children: [
                SizedBox(height: 15,),


                Text("New family ",style: TextStyle(fontSize: 20,letterSpacing: 7.0,fontWeight: FontWeight.bold),),

                Padding(
                  padding: const EdgeInsets.only(top: 25,left: 15,right: 15),
                child:Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Color.fromARGB(255, 202, 202, 202)),
                    
                  ),
                  width: 700,

                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                            SizedBox(height: 10,),

                           Text("External ID",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            SizedBox(height: 13,),
                    
                            Container(
                              width: 304,
                              child:  TextField(
                                  decoration: InputDecoration(
                                    labelText: 'External ID',
                                    prefixIcon: Icon(Icons.align_vertical_bottom),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                    
                            ),
                       
                        SizedBox(height: 10,),
                           Text("Label",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            SizedBox(height: 13,),
                    
                            Container(
                              width: 304,
                              child:  TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Label',
                                    prefixIcon: Icon(Icons.local_offer),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                    
                            ),

                    
                      
                  



                         SizedBox(height: 10,),
                         Text("Type",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),


                          Container(
                    width: 310,
                    height: 49,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 20),
                        Container(
                          width: 276,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '',
                              contentPadding: EdgeInsets.symmetric(horizontal: 1),
                            ),
                            child: DropdownButton<String>(
                              value: selectservices,
                              underline: Container(), // This removes the underline
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectservices = newValue!;
                                  
                                });
                              },
                              items: services.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              icon: Container(
                                padding: EdgeInsets.only(left: 140), // Adjust padding as needed
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.arrow_drop_down), // Dropdown arrow icon
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                           


                            SizedBox(height: 10,),

                  

         SizedBox(height: 20,),

                 Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 1,
                    width: 300,
                    color: Color.fromARGB(255, 215, 201, 201),
                  ),
                  
                  
                ],
              ),
              

              SizedBox(height: 25,),
             
                
                     
                
                   SizedBox(height: 15,),

                   Row(
                     children:[
                      SizedBox(width: 20,),

                      SizedBox(
                      width: 270,
                       child: ElevatedButton(
                                         onPressed: () {
                        // Your onPressed logic goes here
                                         },
                                         style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Color.fromARGB(255, 64, 176, 251),
                        ),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Set your desired border radius
                          ),
                        ),
                        fixedSize: MaterialStateProperty.all<Size>(
                          Size(95, 15), // Set your desired width and heigh
                        ),
                                         ),
                                         child: Text("Submit",style: TextStyle(color: Colors.white)),
                                       ),
                     ),
                     ] 
                   ),
                SizedBox(height: 20,)


                      ],
                    ),
                  ) 
),

                ),
              ],
            ),
          );
  }
}

class Form7 extends StatefulWidget {
  @override
  State<Form7> createState() => _Form7State();
}

class _Form7State extends State<Form7> {
  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  
  List<String>  status = ["Unused",'Used',];
  String selectstatus="Unused";
  var selectedfile;
  @override
  void initState() {
  super.initState();

  }


  @override
  Widget build(BuildContext context) {
    return Container(
            child: Column(
              children: [
                SizedBox(height: 15,),


                Text("New tool ",style: TextStyle(fontSize: 20,letterSpacing: 7.0,fontWeight: FontWeight.bold),),

                Padding(
                  padding: const EdgeInsets.only(top: 25,left: 15,right: 15),
                child:Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Color.fromARGB(255, 202, 202, 202)),
                    
                  ),
                  width: 700,

                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                          
                            SizedBox(height: 10,),

                            SizedBox(height: 10,),
                           Text("External ID",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            SizedBox(height: 13,),
                    
                            Container(
                              width: 304,
                              child:  TextField(
                                  decoration: InputDecoration(
                                    labelText: 'External ID',
                                    prefixIcon: Icon(Icons.align_vertical_bottom),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                    
                            ),
                       
                        SizedBox(height: 10,),
                           Text("Label",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            SizedBox(height: 13,),
                    
                            Container(
                              width: 304,
                              child:  TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Label',
                                    prefixIcon: Icon(Icons.local_offer),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                    
                            ),


                            
                         SizedBox(height: 10,),
                         Text("Status",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                          SizedBox(height: 10,),


                          Container(
                    width: 310,
                    height: 49,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 20),
                        Container(
                          width: 276,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '',
                              contentPadding: EdgeInsets.symmetric(horizontal: 1),
                            ),
                            child: DropdownButton<String>(
                              value: selectstatus,
                              underline: Container(), // This removes the underline
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectstatus = newValue!;
                                  
                                });
                              },
                              items: status.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              icon: Container(
                                padding: EdgeInsets.only(left: 195), // Adjust padding as needed
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.arrow_drop_down), // Dropdown arrow icon
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),


                              
SizedBox(height: 10,),
                           Text("Cost",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            SizedBox(height: 13,),
                    
                            Container(
                              width: 304,
                              child:  TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Cost',
                                    prefixIcon: Icon(Icons.currency_rupee),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                    
                            ),
                       
                        SizedBox(height: 10,),
                           Text("Quantity",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            SizedBox(height: 13,),
                    
                            Container(
                              width: 304,
                              child:  TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Qty',
                                    prefixIcon: Icon(Icons.local_offer),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                    
                            ),

                            SizedBox(height: 10,),
                 Text("Payement Date",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                  SizedBox(height: 10,),

 Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
  width: 304, // Set the desired width here
  height: 46, // Set the desired height here
  decoration: BoxDecoration(
    border: Border.all(
      color: Colors.grey, // You can set the border color here
      width: 1.0, // You can adjust the border width here
    ),
    borderRadius: BorderRadius.circular(8.0), // You can adjust the border radius here
  ),
  child: Row(
    children: [
      SizedBox(width: 30,),
      Text(
        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
        style: TextStyle(fontSize:15,color:Color.fromARGB(255, 116, 116, 116)),
      ),
      SizedBox(width: 162,),
       GestureDetector(
        onTap: () {
         _selectDate(context);
          
        },
        child: Icon(Icons.date_range),
      ),
    ],
  ),
),

           
           
          ],
        ),
 SizedBox(height: 10,),
                 Text("Logo file (peg,png,jpg,gif,svg | max: 10 240 Ko)",style: TextStyle(fontSize: 13,fontWeight: FontWeight.bold),),
                  SizedBox(height: 10,),

        Container(
  width: 310,
          height: 49,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              SizedBox(width: 10,),
              Icon(Icons.image),
              SizedBox(width: 5,),
              Container(
                
                width: 145,
               child: Text("Choose file"),
              ),
                SizedBox(width: 16,),

             ElevatedButton(
  onPressed: () {
   imageupload();
  },
  child: Text("Browse"),
  style: ElevatedButton.styleFrom(
    foregroundColor: Colors.white, backgroundColor: const Color.fromARGB(255, 176, 176, 177), // Text color of the button
    elevation: 5, // Elevation of the button
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
      
        bottomRight: Radius.circular(10),
        topRight: Radius.circular(10)
      ), // Rounded corners
    ),
    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30), // Padding inside the button
  ),
)


            ],
          ),
),


                    
                      
                  




                           


                            SizedBox(height: 10,),

                  

         SizedBox(height: 20,),

                 Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 1,
                    width: 300,
                    color: Color.fromARGB(255, 215, 201, 201),
                  ),
                  
                  
                ],
              ),
              

          
             
                
                     
                
                   SizedBox(height: 15,),

                   Row(
                     children:[
                      SizedBox(width: 20,),

                      SizedBox(
                      width: 270,
                       child: ElevatedButton(
                                         onPressed: () {
                        // Your onPressed logic goes here
                                         },
                                         style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Color.fromARGB(255, 64, 176, 251)
                        ),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Set your desired border radius
                          ),
                        ),
                        fixedSize: MaterialStateProperty.all<Size>(
                          Size(95, 15), // Set your desired width and heigh
                        ),
                                         ),
                                         child: Text("Submit",style: TextStyle(color: Colors.white)),
                                       ),
                     ),
                     ] 
                   ),
                SizedBox(height: 20,)


                      ],
                    ),
                  ) 
),

                ),
              ],
            ),
          );
  }

     void imageupload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() {
          selectedfile = File(result.files.single.path!);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("file selected succesfully"),
          backgroundColor: Color.fromARGB(173, 120, 249, 126),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("error while selecting the file"),
        backgroundColor: Colors.red,
      ));
    }
  }
}

