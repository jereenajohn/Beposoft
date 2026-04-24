import 'package:beposoft/pages/ACCOUNTS/add_Expenses.dart';
import 'package:beposoft/pages/ACCOUNTS/add_Recipt.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/add_credit_note.dart';
import 'package:beposoft/pages/ACCOUNTS/add_new_customer.dart';
import 'package:beposoft/pages/ACCOUNTS/add_new_stock.dart';
import 'package:beposoft/pages/ACCOUNTS/add_staff.dart';
import 'package:beposoft/pages/ACCOUNTS/bank_list.dart';
import 'package:beposoft/pages/ACCOUNTS/credit_note_list.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/daily_goods_movement.dart';
import 'package:beposoft/pages/ACCOUNTS/delivery_list.dart';
import 'package:beposoft/pages/ACCOUNTS/expense_list.dart';
import 'package:beposoft/pages/ACCOUNTS/grv_list.dart';
import 'package:beposoft/pages/ACCOUNTS/new_grv.dart';
import 'package:beposoft/pages/ACCOUNTS/new_performa_products.dart';
import 'package:beposoft/pages/ACCOUNTS/new_product.dart';
import 'package:beposoft/pages/ACCOUNTS/new_proforma_invoice.dart';
import 'package:beposoft/pages/ACCOUNTS/order_list.dart';
import 'package:beposoft/pages/ACCOUNTS/order_products.dart';
import 'package:beposoft/pages/ACCOUNTS/order_request.dart';
import 'package:beposoft/pages/ACCOUNTS/performa_invoice_list.dart';
import 'package:beposoft/pages/ACCOUNTS/product_list.dart';
import 'package:beposoft/pages/ACCOUNTS/purchase_list.dart';
import 'package:beposoft/pages/ACCOUNTS/purchases_request.dart';
import 'package:beposoft/pages/ACCOUNTS/recipts_list.dart';
import 'package:beposoft/pages/ACCOUNTS/transfer.dart';
import 'package:beposoft/pages/ACCOUNTS/view_staff.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/BDM/bdm_order_list.dart';
import 'package:beposoft/pages/BDM/bdm_proforma_invoice.dart';
import 'package:beposoft/pages/BDO/performa_invoice.dart';
import 'package:flutter/material.dart';

class drower{


    void navigateToSelectedPage(BuildContext context, String option) {
    // Navigate to the selected page based on the option
    switch (option) {
      case 'Add Customer':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>add_new_customer()),
        );
        break;
      // case 'Customers':
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(builder: (context) => customer_list()),
      //   );
       // break;
      case 'Add Staff':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>add_staff()),
        );
        break;
      case 'View Staff':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => staff_list()),
        );
        break;
      case 'Add Credit Note':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>add_credit_note()),
        );
        break;
      case 'Credit Note List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => credit_note_list()),
        );
        break;

      
      case 'Add recipts':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_receipt()),
        );
        break;
      case 'Recipts List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => receips()),
        );
        break;
      case 'New Proforma Invoice':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreatePerformaProduct_List()),
        );
        break;
      case 'Proforma Invoice List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProformaInvoiceList()),
        );
        break;

         case 'Delivery Note List':
        Navigator.push(
          
          context,
          MaterialPageRoute(builder: (context) =>WarehouseOrderView(status: null,)),
        );
        break;
      case 'Daily Goods Movement':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => daily_goods_movement()),
        );
        break;
      case 'New Orders':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => order_products()),
        );
        break;
      case 'Orders List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OrderList(status: null,)),
        );
        break;
      case 'Product List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Product_List()),
        );
        break;
          case 'Product Add':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => new_product()),
        );
        break;
      case 'Stock':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_new_stock()),
        );
        break;

       
      case 'Purchase List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => purchase_list()),
        );
        break;
      case 'Add Expence':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_expence()),
        );
        break;
      case 'Expence List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => expence_list()),
        );
        break;
      case 'Sales Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => new_product()),
        );
        break;
      case 'Credit Sales Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_new_stock()),
        );
        break;


        
      
      case 'Statewise Sales Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => purchase_list()),
        );
        break;
      case 'Expence Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_expence()),
        );
        break;
      case 'Delivery Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => expence_list()),
        );
        break;
      case 'Product Sale Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => new_product()),
        );
        break;
      case 'Stock Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_new_stock()),
        );
        break;
         
       
      case 'Create New GRV':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewGrv()),
        );
        break;
      case 'GRVs List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GrvList(status: null,)),
        );
        break;
      case 'Add Bank':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_bank()),
        );
        break;
      case 'List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => bank_list()),
        );
        break;
      // case 'Other Transfer':
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(builder: (context) => transfer()),
      //   );
      //  break;
      default:
        break;
    }
  }
  

}

