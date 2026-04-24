
import 'package:flutter/material.dart';
class Attribute extends ChangeNotifier
{
 static int counter=1;



 var r1;
 var r2;


//   int increment()
//  { 

  
//   r1=counter+1;
//   return r1;
 
//  }
//  int decrement(count){
//   
//   var r2=count-1;
 

//   
//   return r2;

 

//  }

 int set(int set1){
  

  if(set1==1){
    
    counter=counter+1;
    

  }
  else{
     counter=counter-1;
     
     


  }
   return counter;
  

 }



  

}

