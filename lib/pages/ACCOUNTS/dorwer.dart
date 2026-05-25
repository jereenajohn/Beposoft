import 'package:beposoft/Sales%20Directors/DSR_BDO_List.dart';
import 'package:beposoft/Sales%20Directors/sd_confirm_call_duration.dart';
import 'package:beposoft/pages/ACCOUNTS/BDO_call_List.dart';
import 'package:beposoft/pages/ACCOUNTS/add_Expenses.dart';
import 'package:beposoft/pages/ACCOUNTS/add_Recipt.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/add_credit_note.dart';
import 'package:beposoft/pages/BDM/add_team_member.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beposoft/pages/ACCOUNTS/add_customer_type.dart';
import 'package:beposoft/pages/ACCOUNTS/add_daily_sales_report.dart';
import 'package:beposoft/pages/ACCOUNTS/add_new_customer.dart';
import 'package:beposoft/pages/ACCOUNTS/add_new_stock.dart';
import 'package:beposoft/pages/ACCOUNTS/add_product_category.dart';
import 'package:beposoft/pages/ACCOUNTS/add_staff.dart';
import 'package:beposoft/pages/ACCOUNTS/add_team.dart';
import 'package:beposoft/pages/ACCOUNTS/add_warehouse.dart';
import 'package:beposoft/pages/ACCOUNTS/advance_receipt_list.dart';
import 'package:beposoft/pages/ACCOUNTS/bank_list.dart';
import 'package:beposoft/pages/ACCOUNTS/bankrecipt_list.dart';
import 'package:beposoft/pages/ACCOUNTS/cod_transfer.dart';
import 'package:beposoft/pages/ACCOUNTS/cod_transfer_list.dart';
import 'package:beposoft/pages/ACCOUNTS/codsales_report.dart';
import 'package:beposoft/pages/ACCOUNTS/credit_note_list.dart';
import 'package:beposoft/pages/ACCOUNTS/creditsale_report.dart';
import 'package:beposoft/pages/ACCOUNTS/cso_cod_sales_report.dart';
import 'package:beposoft/pages/ACCOUNTS/cso_monthly_sales_report.dart';
import 'package:beposoft/pages/ACCOUNTS/cso_sales_report.dart';
import 'package:beposoft/pages/ACCOUNTS/cso_sold_product_report.dart';
import 'package:beposoft/pages/ACCOUNTS/cso_statewise_report.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/customer_transfer.dart';
import 'package:beposoft/pages/ACCOUNTS/daily_bdo_sales_report.dart';
import 'package:beposoft/pages/ACCOUNTS/daily_goods_movement.dart';
import 'package:beposoft/pages/ACCOUNTS/dailyproductwisecyclingskating.dart';
import 'package:beposoft/pages/ACCOUNTS/damaged_stock_report.dart';
import 'package:beposoft/pages/ACCOUNTS/delivery_report.dart';
import 'package:beposoft/pages/ACCOUNTS/divisionwisereportexcel.dart';
import 'package:beposoft/pages/ACCOUNTS/expence_reeport.dart';
import 'package:beposoft/pages/ACCOUNTS/expense_list.dart';
import 'package:beposoft/pages/ACCOUNTS/finance_report.dart';
import 'package:beposoft/pages/ACCOUNTS/grv_list.dart';
import 'package:beposoft/pages/ACCOUNTS/gstreportpage.dart';
import 'package:beposoft/pages/ACCOUNTS/internal_tranfer.dart';
import 'package:beposoft/pages/ACCOUNTS/monthlyprocyclingskating.dart';
import 'package:beposoft/pages/ACCOUNTS/new_grv.dart';
import 'package:beposoft/pages/ACCOUNTS/new_performa_products.dart';
import 'package:beposoft/pages/ACCOUNTS/new_product.dart';
import 'package:beposoft/pages/ACCOUNTS/order_items_excel_report.dart';
import 'package:beposoft/pages/ACCOUNTS/order_list.dart';
import 'package:beposoft/pages/ACCOUNTS/order_products.dart';
import 'package:beposoft/pages/ACCOUNTS/order_recipts_list.dart';
import 'package:beposoft/pages/ACCOUNTS/performa_invoice_list.dart';
import 'package:beposoft/pages/ACCOUNTS/post_office_report.dart';
import 'package:beposoft/pages/ACCOUNTS/product_list.dart';
import 'package:beposoft/pages/ACCOUNTS/product_stock_report_page.dart';
import 'package:beposoft/pages/ACCOUNTS/purchase_list.dart';
import 'package:beposoft/pages/ACCOUNTS/purchase_request_list.dart';
import 'package:beposoft/pages/ACCOUNTS/purchase_request_products.dart';
import 'package:beposoft/pages/ACCOUNTS/purchases_request.dart';
import 'package:beposoft/pages/ACCOUNTS/recipt.report.dart';
import 'package:beposoft/pages/ACCOUNTS/recipts_list.dart';
import 'package:beposoft/pages/ACCOUNTS/refund.dart';
import 'package:beposoft/pages/ACCOUNTS/refund_list.dart';
import 'package:beposoft/pages/ACCOUNTS/sales_report.dart';
import 'package:beposoft/pages/ACCOUNTS/shipping_address_excel_report.dart';
import 'package:beposoft/pages/ACCOUNTS/sold_product_report.dart';
import 'package:beposoft/pages/ACCOUNTS/statewise_report.dart';
import 'package:beposoft/pages/ACCOUNTS/status_wise_orders_list.dart';
import 'package:beposoft/pages/ACCOUNTS/stock_report.dart';
import 'package:beposoft/pages/ACCOUNTS/team_wise_report.dart';
import 'package:beposoft/pages/ACCOUNTS/tracking_excel.dart';
import 'package:beposoft/pages/ACCOUNTS/transfer_list.dart';
import 'package:beposoft/pages/ACCOUNTS/view_customer_transfer.dart';
import 'package:beposoft/pages/ACCOUNTS/view_staff.dart';
import 'package:beposoft/pages/ADMIN/ceo_daily_productsold_report.dart';
import 'package:beposoft/pages/ADMIN/sales_report_excel.dart';
import 'package:beposoft/pages/BDM/Add_Bdo_present_data.dart';
import 'package:beposoft/pages/BDM/Bdos_dsr_list.dart';
import 'package:beposoft/pages/BDM/active_bdo_list.dart';
import 'package:beposoft/pages/BDM/approve_bdo__call_duration.dart';
import 'package:beposoft/pages/BDM/bdm_add_daily_sales_report.dart';
import 'package:beposoft/pages/BDM/bdm_customer_list.dart';
import 'package:beposoft/pages/BDM/bdm_dsr_list.dart';
import 'package:beposoft/pages/BDM/bdm_report_add.dart';
import 'package:beposoft/pages/BDM/bdm_staff_list.dart';
import 'package:beposoft/pages/BDO/bdo_add_customer.dart';
import 'package:beposoft/pages/BDO/bdo_add_daily_sales_report.dart';
import 'package:beposoft/pages/BDO/bdo_add_dsr_report.dart';
import 'package:beposoft/pages/BDO/bdo_call_duration.dart';
import 'package:beposoft/pages/BDO/bdo_customer_list.dart';
import 'package:beposoft/pages/BDO/bdo_dsr_adding.dart';
import 'package:beposoft/pages/BDO/bdo_dsr_list.dart';
import 'package:beposoft/pages/BDO/bdo_dsr_list2.dart';
import 'package:beposoft/pages/BDO/bdo_order_list.dart';
import 'package:beposoft/pages/BDO/bdo_view_callduration.dart';
import 'package:beposoft/pages/BDO/daily_bdo_sales_report.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_all_orders.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/BDM/bdm_order_list.dart';

import 'package:flutter/material.dart';

class drower {
  Future<void> navigateToSelectedPage(BuildContext context, String option) async {
    // Navigate to the selected page based on the option
    switch (option) {
      case 'Add Customer':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_new_customer()),
        );
        break;
      case 'Customers':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => customer_list()),
        );
        break;
      case 'Customer Type':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_customer_type()),
        );
        break;
      case 'customer Transfer':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => addcustomertransfer()),
        );
        break;
      case 'customer Transfer list':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => customertransferList()),
        );
        break;

      case 'Add Team':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddTeam()),
        );
        break;
      case 'Team wise Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TeamWiseReport()),
        );
        break;

      case 'Add Team Members':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddTeamMembers()),
        );
        break;
      case 'Add Warehouse':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_warehouse()),
        );
        break;
      case 'Add Staff':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_staff()),
        );
        break;
      case 'Staff':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => staff_list()),
        );
        break;
      case 'Add Credit Note':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_credit_note()),
        );
        break;
      case 'Credit Note List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => credit_note_list()),
        );
        break;

      case 'Add Recipt':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_receipt()),
        );
        break;
      case 'Add Refund':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => addrefund()),
        );
      case 'Refund List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RefundList()),
        );

      case 'Add Transfer':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => inernal_transfer()),
        );
      case 'GST Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GSTReportPage()),
        );

      case 'Transfer List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => transfer_list()),
        );

      case 'Recipt List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => recipt_Report()),
        );
        break;
      case 'Bank Recipt':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => bank_recipt_Report()),
        );
        break;

      case 'Advance Recipt':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => advance_recipt_Report()),
        );
        break;

      case 'Order Recipt':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => order_recipt_Report()),
        );
        break;
      case 'COD Transfer':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => cod_transfer()),
        );
        break;
      case 'COD Transfer List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => cod_transfer_list()),
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

      case 'Delivery Note List(Shipped)':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => WarehouseOrderView(
                    status: 'Shipped',
                  )),
        );
        break;
      case 'Delivery Note List(All)':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => warehouse_OrderList(
                    status: 'null',
                  )),
        );
        break;
      case 'Delivery Note List(Packing under Progress)':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => WarehouseOrderView(
                    status: 'Packing under progress',
                  )),
        );
        break;
      case 'Delivery Note List(Packed)':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => WarehouseOrderView(
                    status: 'Packed',
                  )),
        );
        break;
      case 'Delivery Note List(To Print)':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => WarehouseOrderView(
                    status: 'To Print',
                  )),
        );
        break;
      case 'Delivery Note List(Ready to ship)':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => WarehouseOrderView(
                    status: 'Ready to ship',
                  )),
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
      case 'Invoice Created':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OrderList2(
                    status: 'Invoice Created',
                  )),
        );
        break;
      case 'Invoice Approved':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OrderList2(
                    status: 'Invoice Approved',
                  )),
        );
        break;
      case 'Waiting For Confirmation':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OrderList2(
                    status: 'Waiting For Confirmation',
                  )),
        );
        break;
      case 'To Print':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OrderList2(
                    status: 'To Print',
                  )),
        );
        break;
      case 'Packing Under Progress':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OrderList2(
                    status: 'Packing Under Progress',
                  )),
        );
        break;
      case 'Packed':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OrderList2(
                    status: 'Packed',
                  )),
        );
        break;
      case 'Ready to ship':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OrderList2(
                    status: 'Ready to ship',
                  )),
        );
        break;

      case 'Shipped':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OrderList2(
                    status: 'Shipped',
                  )),
        );
        break;
      case 'Invoice Rejected':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OrderList2(
                    status: 'Invoice Rejected',
                  )),
        );
        break;

      case 'Orders List':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OrderList(
                    status: null,
                  )),
        );
        break;
      case 'Orders':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => bdm_OrderList(
                    status: null,
                  )),
        );
      case 'Product List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Product_List()),
        );
        break;

      case 'BDO Call List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BdoCallList()),
        );
        break;

      case 'Purchase request':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => request_order_products()),
        );
        break;
      case 'Purchase request List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => purchase_List(status: null)),
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
      case 'Add Product Category':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_pro_categories()),
        );
        break;
      case 'Product Category List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => expence_list()),
        );
        break;
      case 'Sales Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Sales_Report()),
        );
        break;
      case 'Sales Report Excel':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SalesReportExcel()),
        );
        break;
      case 'Daily Product Sold Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CeoDailyProductsoldReport()),
        );
        break;
      case 'Cycling & Skating Monthly Excel':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CyclingProductwiseStatewiseReport()),
        );
        break;
     case 'Order Items Excel Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OrderItemsExcelReport()),
        );

      case 'Shipping Address Excel Report':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShippingAddressExcelReport(
              warehouseId: 1,
              fromDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
              toDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            ),
          ),
        );

      case 'Product Stock Report':
        final prefs = await SharedPreferences.getInstance();
        final int warehouseId = prefs.getInt('warehouse') ?? 1;
        final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductStockReportPage(
              warehouseId: warehouseId,
              fromDate: today,
              toDate: today,
            ),
          ),
        );
        break;

      case 'Cycling & Skating Daily Excel':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CyclingskatingDailyProductwiseReport()),
        );
        break;

      case 'All Division Product Sale Report':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DivisionProductwiseStatewiseReport()),
        );
        break;
      case 'Tracking Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => trackingReport()),
        );
        break;
      case 'CSO Sales Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => cso_Sales_Report()),
        );
        break;
      case 'CSO Monthly Sales Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CsoMonthlySalesReport()),
        );
        break;
      case 'CSO COD Sales Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => csoCodSales2()),
        );
        break;
      case 'CSO Statewise Sales Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => cso_StateWiseReport2()),
        );
        break;
      case 'CSO Product Sale Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => cso_Sold_pro_report()),
        );
        break;

      case 'Recipt Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => recipt_Report()),
        );
        break;
      case 'Credit Sales Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Creditsalereport2()),
        );
        break;

      case 'COD Sales Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CodSales2()),
        );
        break;
      case 'Statewise Sales Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StateWiseReport2()),
        );
        break;
      case 'Expence Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Expence_Report()),
        );
        break;
      case 'Delivery Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Delivery_Report()),
        );
        break;
      case 'Product Sale Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Sold_pro_report()),
        );
        break;
      case 'Stock Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Stock_Report()),
        );
        break;

      case 'Damaged Stock':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DamagedStockReport()),
        );
        break;

      case 'Finance Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FinancialReport()),
        );
        break;
      case 'Actual Delivery Report':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PostofficeReport()),
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
          MaterialPageRoute(
              builder: (context) => GrvList(
                    status: null,
                  )),
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
      //   break;
      default:
        break;
    }
  }

  void navigateToSelectedPage2(BuildContext context, String option) {
    // Navigate to the selected page based on the option
    switch (option) {
      case 'Create Proforma Invoice':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreatePerformaProduct_List()),
        );
        break;
      case 'View Proforma Invoice':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProformaInvoiceList()),
        );
        break;
      case 'View Customers':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => bdo_customer_list()),
        );
        break;
      case 'Add New Customers':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => bdo_add_new_customer()),
        );
        break;

      case 'Create Orders':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => order_products()),
        );
        break;
      case 'View Order List':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => bod_oredr_list(
                    status: null,
                  )),
        );
        break;

      case 'Add Daily Sales':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BdoAddDailySalesReport()),
        );
        break;
      case 'DSR List':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => BDODailySalesReportViewPage()),
        );
        break;

      case 'Add DSR':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BdoAddDsrReport()),
        );
        break;
      case 'View Sales Report List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BdoDsrList()),
        );
        break;

      case 'BDO ADD DSR':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BdoDsrAdding()),
        );
        break;

      case 'VIEW DSR LIST':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BdoDsrList2()),
        );
        break;

      case 'BDO ADD CALL DURATION':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BdoCallDuration()),
        );
        break;

      case 'VIEW CALL DURATION LIST':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BdoViewCallduration()),
        );
        break;
      case 'Product List':
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

      // case 'COD Sales Report':
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) =>Purchases_request()),
      // );
      // break;
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
          MaterialPageRoute(builder: (context) => Delivery_Report()),
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

      case 'Damaged Stock':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DamagedStockReport()),
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
          MaterialPageRoute(
              builder: (context) => GrvList(
                    status: null,
                  )),
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
      //   break;
      default:
        break;
    }
  }

  void navigateToSelectedPage3(BuildContext context, String option) {
    // Navigate to the selected page based on the option
    switch (option) {
      case 'Add Team':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddTeam()),
        );
        break;

      case 'Add Team Members':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddTeamMembers()),
        );
        break;

      case 'View Call Duration List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => approvebdocallduration()),
        );
        break;

      case 'Add Team Members':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddTeamMembers()),
        );
        break;

      case 'Approve BDO Call Duration':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SdConfirmCallDuration()),
        );
        break;

      case 'Add BDO Attendence':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BdmReportAdd()),
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
      case 'Customers':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => bdm_customer_list()),
        );
        break;
      case 'Add Customer':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_new_customer()),
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
          MaterialPageRoute(
              builder: (context) => bdm_OrderList(
                    status: null,
                  )),
        );
        break;

      case 'Add DSR':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddBDMBDOReportPage()),
        );
        break;
      case 'DSR List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BdmDsrList()),
        );
        break;

      case 'BDO DSR List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BdosDsrList()),
        );
        break;
      case 'DSR BDO List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DsrBdoList()),
        );
        break;
      case 'Add Attendence':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BdmReportAdd()),
        );
        break;

      case 'Add Active Bdo Data':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddBdmOrderSelectionPage()),
        );
        break;
      case 'Active BDO List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BdmOverallReportPage()),
        );
        break;

      case 'Product List':
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
          MaterialPageRoute(builder: (context) => Delivery_Report()),
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

      case 'Damaged Stock':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DamagedStockReport()),
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
          MaterialPageRoute(
              builder: (context) => GrvList(
                    status: null,
                  )),
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
      case 'Add Staff':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_staff()),
        );
        break;
      case 'Staff':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => staff_list()),
        );
        break;

      case 'Add Credit Note':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => add_credit_note()),
        );
        break;
      default:
        break;
    }
  }
}
