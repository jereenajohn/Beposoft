import 'dart:convert';
import 'dart:io';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/api.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

class CustomerLedger extends StatefulWidget {
  final int customerid;
  final String customerName;
  const CustomerLedger(
      {Key? key, required this.customerid, required this.customerName})
      : super(key: key);

  @override
  State<CustomerLedger> createState() => _CustomerLedgerState();
}

class _CustomerLedgerState extends State<CustomerLedger> {
  List<Map<String, dynamic>> ledgerEntries = [];
  List<Map<String, dynamic>> filteredEntries = [];
  List<Map<String, dynamic>> companyList = [];

  double totalDebit = 0.0;
  double totalCredit = 0.0;
  DateTime? startDate;
  DateTime? endDate;

  String? selectedCompany;

  @override
  void initState() {
    super.initState();
    getCompanyList().then((_) {
      fetchCustomerLedgerDetails();
    });

    
    
  }

  Future<String?> getTokenFromPrefs() async {
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

  Future<void> getCompanyList() async {
  try {
    final token = await getTokenFromPrefs();
    var response = await http.get(
      Uri.parse('$api/api/company/data/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decodedResponse['data'] as List<dynamic>; // Access the 'data' key

      setState(() {
        companyList = data
            .map((company) => {
                  'id': company['id'],
                  'name': company['name'],
                })
            .toList();
            
      });
    } else {
      
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
Future<void> fetchCustomerLedgerDetails() async {
  try {
    final token = await getTokenFromPrefs();

    final response = await http.get(
      Uri.parse('$api/api/customer/${widget.customerid}/ledger/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) return;

    final parsed = jsonDecode(response.body);

    final ledgerData =
        parsed['data']['ledger'] as List<dynamic>? ?? [];
    final advanceReceipts =
        parsed['data']['advance_receipts'] as List<dynamic>? ?? [];
    final paymentReceipts =
        parsed['data']['payment_receipts'] as List<dynamic>? ?? [];
    final grvList =
        parsed['data']['grv'] as List<dynamic>? ?? [];
    final refundReceipts =
        parsed['data']['refund_receipts'] as List<dynamic>? ?? [];

    /// ✅ NEW
    final ledgerSentTransfers =
        parsed['data']['ledger_sent_transfers'] as List<dynamic>? ?? [];
    final advanceTransfers =
        parsed['data']['advance_transfers'] as List<dynamic>? ?? [];

    List<Map<String, dynamic>> entries = [];
    double debitSum = 0.0;
    double creditSum = 0.0;

    /// 🔹 Map orderId → invoice
    final Map<int, String> orderIdToInvoice = {};
    for (var entry in ledgerData) {
      if (entry['id'] != null && entry['invoice'] != null) {
        orderIdToInvoice[entry['id']] = entry['invoice'].toString();
      }
    }

    /// 🔹 DEBIT — GOODS SALE
    for (var entry in ledgerData) {
      if (entry['status'] != 'Invoice Rejected' &&
          entry['status'] != 'Invoice Created') {
        double debitAmount =
            double.tryParse(entry['total_amount'].toString()) ?? 0.0;

        if (debitAmount > 0) {
          debitSum += debitAmount;

          entries.add({
            'date': entry['order_date'],
            'invoice': '${entry['invoice']}/${entry['company']}',
            'company': entry['company'],
            'particular': 'Goods Sale',
            'debit': debitAmount,
            'credit': null,
            'isFirstOfOrder': true,
          });
        }
      }
    }

    /// 🔹 DEBIT — REFUND RECEIPTS
    for (var refund in refundReceipts) {
      double debitAmount =
          double.tryParse(refund['amount'].toString()) ?? 0.0;

      if (debitAmount > 0) {
        debitSum += debitAmount;

        entries.add({
          'date': refund['date'],
          'invoice': refund['invoice_no'] ?? refund['refund_no'],
          'company': refund['bank_name'] ?? '',
          'particular': 'Refund Paid',
          'debit': debitAmount,
          'credit': null,
          'receipt_no': refund['refund_no'],
          'transaction_id': refund['transactionID'],
          'note': refund['note'],
          'isFirstOfOrder': false,
        });
      }
    }

    /// 🔴 DEBIT — LEDGER SENT TRANSFERS (NEW)
    for (var sent in ledgerSentTransfers) {
      double debitAmount =
          double.tryParse(sent['amount']?.toString() ?? '0') ?? 0.0;

      if (debitAmount > 0) {
        debitSum += debitAmount;

        entries.add({
          'date': sent['date'],
          'invoice': 'TRANSFER-${sent['id']}',
          'company': sent['send_to_name'],
          'particular': 'Amount Transferred',
          'debit': debitAmount,
          'credit': null,
          'note': sent['note'],
          'transaction_id': sent['id'],
          'isFirstOfOrder': false,
        });
      }
    }

    /// 🔹 CREDIT — ADVANCE RECEIPTS
    for (var adv in advanceReceipts) {
      double creditAmount =
          double.tryParse(adv['amount'].toString()) ?? 0.0;

      if (creditAmount > 0) {
        creditSum += creditAmount;

        entries.add({
          'date': adv['received_at'],
          'invoice': adv['payment_receipt'],
          'company': adv['bank_name'],
          'particular': 'Advance Payment',
          'debit': null,
          'credit': creditAmount,
          'isFirstOfOrder': false,
        });
      }
    }

    /// 🟢 CREDIT — ADVANCE TRANSFERS (NEW)
    for (var adv in advanceTransfers) {
      double creditAmount =
          double.tryParse(adv['amount']?.toString() ?? '0') ?? 0.0;

      if (creditAmount > 0) {
        creditSum += creditAmount;

        entries.add({
          'date': adv['date'],
          'invoice': 'ADV-TR-${adv['id']}',
          'company': adv['send_from_name'],
          'particular': 'Advance Transfer Received',
          'debit': null,
          'credit': creditAmount,
          'note': adv['note'],
          'transaction_id': adv['id'],
          'isFirstOfOrder': false,
        });
      }
    }

    /// 🔹 CREDIT — PAYMENT RECEIPTS
    for (var pay in paymentReceipts) {
      double creditAmount =
          double.tryParse(pay['amount'].toString()) ?? 0.0;

      if (creditAmount > 0) {
        creditSum += creditAmount;

        String invoiceNo = '';
        if (pay['order'] != null &&
            orderIdToInvoice.containsKey(pay['order'])) {
          invoiceNo = orderIdToInvoice[pay['order']]!;
        }

        entries.add({
          'date': pay['received_at'],
          'invoice': invoiceNo.isNotEmpty
              ? '$invoiceNo/${pay['bank']}'
              : pay['payment_receipt'],
          'company': pay['bank'],
          'particular': 'Payment Received',
          'debit': null,
          'credit': creditAmount,
          'receipt_no': pay['payment_receipt'],
          'transaction_id': pay['transactionID'],
          'isFirstOfOrder': false,
        });
      }
    }

    /// 🔹 CREDIT — GRV (APPROVED ONLY)
    for (var grv in grvList) {
      final remark = (grv['remark'] ?? '').toString().toLowerCase();
      final status = (grv['status'] ?? '').toString().toLowerCase();

      if (status != 'approved') continue;

      double creditAmount = 0.0;
      String particular = '';

      if (remark == 'refund') {
        creditAmount =
            double.tryParse(grv['price']?.toString() ?? '0') ?? 0.0;
        particular = 'Refund GRV';
      } else if (remark == 'cod_return') {
        creditAmount =
            double.tryParse(grv['cod_amount']?.toString() ?? '0') ?? 0.0;
        particular = 'COD Return GRV';
      }

      if (creditAmount > 0) {
        creditSum += creditAmount;

        entries.add({
          'date': grv['date'],
          'invoice': grv['invoice'],
          'company': '',
          'particular': particular,
          'debit': null,
          'credit': creditAmount,
          'note': grv['note'],
          'isFirstOfOrder': false,
        });
      }
    }

    /// 🔹 SORT BY DATE
    entries.sort(
      (a, b) => a['date'].toString().compareTo(b['date'].toString()),
    );

    /// 🔹 UPDATE UI
    setState(() {
      ledgerEntries = entries;
      filteredEntries = entries;
      totalDebit = debitSum;
      totalCredit = creditSum;
    });
  } catch (e) {
  }
}

  void filterEntriesByCompanyAndDate() {
    double debitSum = 0.0;
    double creditSum = 0.0;

    setState(() {
      filteredEntries = ledgerEntries.where((entry) {
        final entryDate = DateTime.parse(entry['date']);

        // Date filtering
        final isOnSelectedDate = startDate != null &&
            endDate == null &&
            entryDate.year == startDate!.year &&
            entryDate.month == startDate!.month &&
            entryDate.day == startDate!.day;

        final isWithinDateRange = startDate != null &&
            endDate != null &&
            entryDate.isAfter(startDate!.subtract(Duration(days: 1))) &&
            entryDate.isBefore(endDate!.add(Duration(days: 1)));

        bool dateMatch =
            startDate == null || isOnSelectedDate || isWithinDateRange;

        // Company filtering
        bool companyMatch = selectedCompany == null ||
            selectedCompany == "All Companies" ||
            entry['company'] == selectedCompany;

        return dateMatch && companyMatch;
      }).toList();

      for (var entry in filteredEntries) {
        debitSum += entry['debit'] ?? 0.0;
        creditSum += entry['credit'] ?? 0.0;
      }

      totalDebit = debitSum;
      totalCredit = creditSum;
    });
  }

  Future<void> exportToExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Customer Ledger'];

    sheetObject.appendRow(
        ['#', 'Date', 'Invoice', 'Particular', 'Debit (₹)', 'Credit (₹)']);

    for (int i = 0; i < filteredEntries.length; i++) {
      final entry = filteredEntries[i];
      sheetObject.appendRow([
        "${i + 1}",
        entry['date'] ?? '',
        entry['invoice'] ?? '',
        entry['particular'] ?? '',
        entry['debit']?.toString() ?? '',
        entry['credit']?.toString() ?? '',
      ]);
    }

    sheetObject.appendRow([]);
    sheetObject.appendRow([
      'Grand Total',
      '',
      '',
      '',
      totalDebit.toStringAsFixed(2),
      totalCredit.toStringAsFixed(2),
    ]);
    if(totalCredit>totalDebit){
    sheetObject.appendRow([
      'Closing Balance',
      '',
      '',
      '',
       '',
      (totalCredit - totalDebit).toStringAsFixed(2),
     
    ]);
    }
    final tempDir = await getTemporaryDirectory();
    final tempPath = "${tempDir.path}/customer_ledger_preview.xlsx";
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(await excel.encode()!);

    await OpenFilex.open(tempPath);
  }

  Future<void> saveExcelToDownloads(String tempPath) async {
    final directory = await getExternalStorageDirectory();
    final downloadPath = "${directory!.path}/Download/customer_ledger.xlsx";
    final file = File(tempPath);

    await file.copy(downloadPath);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text("Excel file saved to Downloads folder: customer_ledger.xlsx"),
    ));
  }

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.start == picked.end ? null : picked.end;
        filterEntriesByCompanyAndDate();
      });
    }
  }
  
Future<pw.Document> createInvoice() async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title Section
              pw.Center(
                child: pw.Text(
                  '${widget.customerName.toUpperCase()} COMPLETE PDF LEDGER',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Table Headers
              pw.Table.fromTextArray(
                headers: [
                  'No', 'Date', 'Invoice', 'Particular', 'Debit', 'Credit'
                ],
                data: [
                  for (int i = 0; i < filteredEntries.length; i++)
                    [
                      i + 1,
                      filteredEntries[i]['date'] ?? '',
                      filteredEntries[i]['invoice'] ?? '',
                      filteredEntries[i]['particular'] ?? '',
                      filteredEntries[i]['debit']?.toStringAsFixed(2) ?? '',
                      filteredEntries[i]['credit']?.toStringAsFixed(2) ?? '',
                    ]
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
                cellStyle: pw.TextStyle(
                  fontSize: 8,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                rowDecoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                  ),
                ),
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                },
              ),
              pw.SizedBox(height: 10),
              
              // Grand Total and Closing Balance
              pw.Divider(thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Grand Total',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    'Debit: Rs ${totalDebit.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Text(
                    'Credit: Rs ${totalCredit.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
                            pw.SizedBox(height: 10),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Closing Balance',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, color: PdfColors.green),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Text(
                    'Rs ${(totalDebit - totalCredit).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, color: PdfColors.green),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );

  return pdf;
}

  Future<void> downloadInvoice() async {
    final pdf = await createInvoice();
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/${widget.customerName}_Ledger.pdf");
    await file.writeAsBytes(await pdf.save());
    await Printing.sharePdf(bytes: await pdf.save(), filename: '${widget.customerName}_Ledger.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
     title: Text(
          "Customer Ledger",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Custom back arrow
          onPressed: () {
                     Navigator.pop(context);  
          },
        ),
  actions: [
    PopupMenuButton<String>(
      icon: Icon(Icons.more_vert), // 3-dot icon
      onSelected: (value) {
        // Handle menu item selection
        switch (value) {
          case 'Option 1':
           exportToExcel();
            break;
          case 'Option 2':
           downloadInvoice();
            break;
         
          default:
            // Handle default case
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
            value: 'Option 1',
            child: Text('Export Excel'),
          ),
          PopupMenuItem<String>(
            value: 'Option 2',
            child: Text('Download Pdf'),
          ),
          
        ];
      },
    ),
  ],
  
),

 
      body: Column(
        children: [
          SizedBox(height: 15,),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedCompany,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCompany = newValue;
                        filterEntriesByCompanyAndDate();
                      });
                    },
                    items: [
                      DropdownMenuItem<String>(
                        value: "All Companies",
                        child: Text("All Companies"),
                      ),
                      ...companyList
                          .map<DropdownMenuItem<String>>((companyItem) {
                        return DropdownMenuItem<String>(
                          value: companyItem['name'],
                          child: Text(companyItem['name'] ?? ''),
                        );
                      }).toList(),
                    ],
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                    dropdownColor: Colors.white,
                    isExpanded: true,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: pickDateRange,
                  tooltip: "Select Date Range",
                ),
              ],
            ),
          ),
          if (startDate != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    endDate == null
                        ? 'Selected Date: ${DateFormat('yyyy-MM-dd').format(startDate!)}'
                        : 'Selected Date Range: ${DateFormat('yyyy-MM-dd').format(startDate!)} - ${DateFormat('yyyy-MM-dd').format(endDate!)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
                      SizedBox(height: 10,),

          Expanded(
            child: filteredEntries.isEmpty
                ? Center(
                    child: Text(
                      "No Orders Available",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        children: [
                          DataTable(
                            headingRowColor: MaterialStateColor.resolveWith(
                                (states) => Colors.blue.shade100),
                            dataRowColor:
                                MaterialStateColor.resolveWith((states) {
                              return states.contains(MaterialState.selected)
                                  ? Colors.blue.shade50
                                  : Colors.grey.shade200;
                            }),
                            columnSpacing: 20,
                            columns: const [
                              DataColumn(
                                  label: Text('#',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Date',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Invoice',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Particular',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Debit (₹)',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Credit (₹)',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                            ],
                            rows: () {
                              int mainOrderCounter = 1;
                              String? previousInvoice;

                              return List.generate(filteredEntries.length + 2,
                                  (index) {
                                if (index < filteredEntries.length) {
                                  final entry = filteredEntries[index];
                                  final currentInvoice = entry['invoice'];
                                  bool isMainOrder =
                                      entry['isFirstOfOrder'] == true;
                                  String displayNumber;

                                  if (isMainOrder) {
                                    displayNumber = mainOrderCounter.toString();
                                    mainOrderCounter++;
                                    previousInvoice = currentInvoice;
                                  } else {
                                    int subOrderCounter = 1;
                                    displayNumber =
                                        "${mainOrderCounter - 1}.$subOrderCounter";
                                    subOrderCounter++;
                                  }

                                  return DataRow(cells: [
                                    DataCell(Text(displayNumber)),
                                    DataCell(Text(entry['date'] ?? '')),
                                    DataCell(Text(
                                        isMainOrder ? currentInvoice : '',
                                        style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold))),
                                    DataCell(Text(entry['particular'] ?? '',
                                        style: TextStyle(
                                            color: entry['particular'] ==
                                                    'Goods Sale'
                                                ? Colors.red
                                                : Colors.green,
                                            fontWeight: FontWeight.bold))),
                                    DataCell(
                                        Text(entry['debit']?.toString() ?? '')),
                                    DataCell(Text(
                                        entry['credit']?.toString() ?? '')),
                                  ]);
                                } else if (index == filteredEntries.length) {
                                  return DataRow(cells: [
                                    DataCell(Text('Grand Total',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black))),
                                    DataCell(Text('')),
                                    DataCell(Text('')),
                                    DataCell(Text('')),
                                    DataCell(Text(totalDebit.toStringAsFixed(2),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade800))),
                                    DataCell(Text(
                                        totalCredit.toStringAsFixed(2),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade800))),
                                  ]);
                                }// ...existing code...
else {
  final closingBalance = (totalDebit - totalCredit).abs();
  final isCredit = totalCredit > totalDebit;
  return DataRow(cells: [
    DataCell(Text('Closing Balance',
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepOrangeAccent))),
    DataCell(Text('')),
    DataCell(Text('')),
    DataCell(Text('')),
    DataCell(
      isCredit
          ? Text('',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 249, 31, 31)))
          : Text(
              closingBalance.toStringAsFixed(2),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 252, 40, 40)))),
    DataCell(
      isCredit
          ? Text(
              closingBalance.toStringAsFixed(2),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 0, 184, 25)))
          : Text('',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 1, 198, 11)))),
  ]);
}
// ...existing code...
                              });
                            }(),
                          )
                        ],
                      ),
                    ),
                  ),
          ),
          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: ElevatedButton.icon(
          //     icon: Icon(Icons.download),
          //     label: Text("Export to Excel"),
          //     onPressed: exportToExcel,
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: Colors.white,
          //       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          //       textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          //     ),
          //   ),
          // ),
          // ElevatedButton.icon(
          //   icon: Icon(Icons.picture_as_pdf),
          //   label: Text("Generate PDF"),
          //   onPressed: () async {
          //     // Print to check filtered entries before generating PDF
          //     
          //     downloadInvoice();
          //   },
          //   style: ElevatedButton.styleFrom(
          //     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          //     textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          //   ),
          // ),
        ],
      ),
    );
  }
}
