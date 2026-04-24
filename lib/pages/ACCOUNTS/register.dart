
import 'package:flutter/material.dart';

class register extends StatefulWidget {
  const register({super.key});

  @override
  State<register> createState() => _registerState();
}

class _registerState extends State<register> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: SingleChildScrollView(
        child: Container(
          child: Column(
          
            children: [
              SizedBox(height: 80,),
               Image.asset(
                          "lib/assets/logo_black.png",
                          width: 100, // Change width to desired size
                          height: 100, // Change height to desired size
                          fit: BoxFit
                              .contain, // Use BoxFit.contain to maintain aspect ratio
                        ),
                       
                      
        Padding(
          padding: const EdgeInsets.only(left: 20,),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9, // Responsive width
            height: MediaQuery.of(context).size.height * 0.7, // Responsive height
            decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10), // Adjust the radius as needed
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                      children: [
                      
                         Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
              color: Color.fromARGB(255, 38, 156, 235),
              borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
              ),
              border: Border.all(color: Color.fromARGB(255, 202, 202, 202)),
              boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 254, 252, 252).withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 1),
                      ),
              ],
                        ),
                        child: Column(
              children: [
                      Text(
                        " Register",
                        style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 13),
                      // Add more widgets here as needed
              ],
                        ),
                      ),
                      SizedBox(height: 30,),
                      
                      TextField(
                            decoration: InputDecoration(
                              labelText: 'Name of customer',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                            ),
                          ),
                           SizedBox(height: 10,),
                      
                       TextField(
                            decoration: InputDecoration(
                              labelText: 'username',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                            ),
                          ),
                           SizedBox(height: 15,),
                      
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                            ),
                          ),
                           SizedBox(height: 15,),
                      
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                            ),
                          ),
                           SizedBox(height: 15,),
                      
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Retype password',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                            ),
                          ),
                           SizedBox(height: 20,),
                      
                      
                          ElevatedButton(onPressed: (){}, style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                     Color.fromARGB(255, 38, 156, 235),
                    ),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(1), // Set your desired border radius
                      ),
                    ),
                    fixedSize: MaterialStateProperty.all<Size>(
                      Size(300, 15), // Set your desired width and heigh
                    ),
                  ), child: Text('Register',style: TextStyle(color: Colors.white),)),
                  SizedBox(height: 20,),


                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              TextButton(
                                onPressed: () {
                                  // Add your onPressed logic here
                                },
                                child: Text(
                                  "I already have a membership",
                                  style: TextStyle(
                                    fontSize: 13,
                                   
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          )
                      
                      
                      ],
              ),
            ),
          ),
        ),



        
        
        
        
            ],
          ),
        ),
      ),
    );
  }
}