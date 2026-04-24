import 'package:beposoft/pages/ACCOUNTS/credit_note_list.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/BDO/bdo_add_customer.dart';
import 'package:beposoft/pages/BDO/bdo_customer_list.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/BDO/bdo_order_list.dart';
import 'package:beposoft/pages/BDO/performa_invoice.dart';
import 'package:flutter/material.dart';
class performa_invoice extends StatefulWidget {
  const performa_invoice({super.key});

  @override
  State<performa_invoice> createState() => _performa_invoiceState();
}

class _performa_invoiceState extends State<performa_invoice> {

   List<String>  bank = ["anand",'yogi','hari',"jerry",'navi','megha'];
  String selectbank="anand";
    
  List<String>  categories = ["cycling",'skating','fitnass','bepocart'];
  String selectededu="cycling";
      
  List<String>  manager= ["jeshiya",'hanvi','nimitha','sandheep','sulfi'];
  String selectmanager="jeshiya";
  List<String>  address= ["empty",];
  String selectaddress="empty";

//dateselection
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
  drower d=drower();

    Widget _buildDropdownTile(BuildContext context, String title, List<String> options) {
    return ExpansionTile(
      title: Text(title),
      children: options.map((option) {
        return ListTile(
          title: Text(option),
          onTap: () {
            Navigator.pop(context);
            d.navigateToSelectedPage2(context, option); // Navigate to selected page
          },
        );
      }).toList(),
    );
  }


  //searchable dropdown

 final List<String> items = [
    'A_Item1',
    'A_Item2',
    'A_Item3',
    'A_Item4',
    'B_Item1',
    'B_Item2',
    'B_Item3',
    'B_Item4',
    "anii"
  ];

  String? selectedValue;
  final TextEditingController textEditingController = TextEditingController();

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }
  List<String>  company = ["BEPOSITIVE RACING PRIVATE LIMITED",'MICHAEL EXPORT AND IMPORT PRIVATE LIMITED'];
  String selectcomp="BEPOSITIVE RACING PRIVATE LIMITED";
  
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
                Navigator.push(context, MaterialPageRoute(builder: (context)=>bdo_dashbord()));
              },
            ),
                  ListTile(
              leading: Icon(Icons.person),
              title: Text('Customer'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>bdo_customer_list()));
              },
            ),
             Divider(),
         
            _buildDropdownTile(context, 'Proforma Invoice', ['New Proforma Invoice', 'Proforma Invoice List',]),
            _buildDropdownTile(context, 'Orders', ['New Orders', 'Orders List']),
             Divider(),

             Text("Others"),
             Divider(),






           

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

          child: Container(
            child: Column(
              children: [
                SizedBox(height: 15,),


                Text("ORDER REQUEST ",style: TextStyle(fontSize: 20,letterSpacing: 9.0,fontWeight: FontWeight.bold),),

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
                        SizedBox(height: 20,),

                 Text("Select Company *",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                  SizedBox(height: 10,),


                         Container(
                             width: 304,
                             decoration: BoxDecoration(
                               border: Border.all(color: Colors.grey), // Add border to the Container
                               borderRadius: BorderRadius.circular(10.0), // Optional: Add border radius
                             ),
                             child: InputDecorator(
                               decoration: InputDecoration(
                                 border: InputBorder.none,
                                 hintText: '',
                                 contentPadding: EdgeInsets.symmetric(horizontal: 1),
                               ),
                               child: DropdownButton<String>(
                                 value: selectcomp,
                                 underline: Container(), // This removes the underline
                                 onChanged: (String? newValue) {
                                   setState(() {
                                     selectcomp = newValue!;
                                     
                                   });
                                 },
                                 items: company.map<DropdownMenuItem<String>>((String value) {
                                   return DropdownMenuItem<String>(
                                     value: value,
                                     child: Text(
                                       value,
                                       style: TextStyle(fontSize: 10), // Set the font size here
                                     ),
                                   );
                                 }).toList(),
                                 icon: Container(
                                   padding: EdgeInsets.only(left: 30), // Adjust padding as needed
                                   alignment: Alignment.centerRight,
                                   child: Icon(Icons.arrow_drop_down), // Dropdown arrow icon
                                 ),
                               ),
                             ),
                           ),
                        
                                    
                SizedBox(height: 10,),
                 Text("Select Family *",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                  SizedBox(height: 10,),

                      Container(
                    width: 310,
                    height: 49,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color.fromARGB(255, 62, 62, 62)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 20),
                        Container(
                          width: 280,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Select your class',
                              contentPadding: EdgeInsets.symmetric(horizontal: 1),
                            ),
                            child: DropdownButton<String>(
                              value: selectededu,
                              underline: Container(), // This removes the underline
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectededu = newValue!;
                                  
                                });
                              },
                              items: categories.map<DropdownMenuItem<String>>((String value) {
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

                                         
                SizedBox(height: 10,),
                 Text("Select Customer *",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                  SizedBox(height: 10,),


                  Row(
                    children: [
                     Container(
                      child: Row(
                        children: [

                         Container(
          width: 50,
          height: 48,
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 223, 223, 222),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
          ),
          child: GestureDetector(
            onTap: () {

              Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => bdo_add_new_customer()));
            
              
            },
            child: Image.asset(
              'lib/assets/addnew.png',
              height: 20,
              width: 20,
            ),
          ),
        ),
    
                                   Container(
                    width: 254, 
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10),
                            bottomRight: Radius.circular(10)
                          ),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                      ),
                    ),
                  ),

                        ],
                      ),
                     )

                    ],



                  ),

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
                              value: selectbank,
                              underline: Container(), // This removes the underline
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectbank = newValue!;
                                  
                                });
                              },
                              items: bank.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              icon: Container(
                                padding: EdgeInsets.only(left: 190), // Adjust padding as needed
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
                 Text("Invoice ID",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                  SizedBox(height: 10,),

 Container(
                              width: 304,
                              child:  TextField(
                                  decoration: InputDecoration(
                                    labelText: 'IN/--',
                                    prefixIcon: Icon(Icons.insert_drive_file),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
                                  ),
                                ),
                    
                            ),

                        
                    
                        SizedBox(height: 10,),
                           Text("Name of new invoice",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            SizedBox(height: 10,),
                    
                            Container(
                              width: 304,
                              child:  TextField(
                                  decoration: InputDecoration(
                                    labelText: 'IN/--',
                                    prefixIcon: Icon(Icons.info_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 8.0), // Set vertical padding
                                  ),
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
                              value: selectmanager,
                              underline: Container(), // This removes the underline
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectmanager = newValue!;
                                  
                                });
                              },
                              items: manager.map<DropdownMenuItem<String>>((String value) {
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
                     
                            

                  

        

              SizedBox(height: 25,),
             
                  Text("Bill To*",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
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
                              value: selectaddress,
                              underline: Container(), // This removes the underline
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectaddress = newValue!;
                                  
                                });
                              },
                              items: address.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              icon: Container(
                                padding: EdgeInsets.only(left: 190), // Adjust padding as needed
                                alignment: Alignment.centerRight,
                                child: Icon(Icons.arrow_drop_down), // Dropdown arrow icon
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),


                  SizedBox(height: 25,),
             
                  Text("Ship To*",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
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
                              value: selectaddress,
                              underline: Container(), // This removes the underline
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectaddress = newValue!;
                                  
                                });
                              },
                              items: address.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              icon: Container(
                                padding: EdgeInsets.only(left: 190), // Adjust padding as needed
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
                 Text("Invoice Date",style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                  SizedBox(height: 10,),

 Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
  width: 304, 
  height: 46, 
  decoration: BoxDecoration(
    border: Border.all(
      color: Colors.grey, 
      width: 1.0, 
    ),
    borderRadius: BorderRadius.circular(8.0), 
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
                 

             
             


                          

                  


                           
                   SizedBox(height: 15,),

                   ElevatedButton(
                  onPressed: () {
                    // Your onPressed logic goes here
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Color.fromARGB(255, 17, 173, 0),
                    ),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), 
                      ),
                    ),
                    fixedSize: MaterialStateProperty.all<Size>(
                      Size(95, 15), 
                    ),
                  ),
                  child: Text("Add Product",style: TextStyle(color: Colors.white)),
                ),
                SizedBox(height: 20,)     
                    
                      ],
                    ),
                  )
                  
  
  
),

                ),

               

              ],
            ),
          )

        ),


    );
  }



}