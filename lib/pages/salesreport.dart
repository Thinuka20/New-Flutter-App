import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:get/get.dart';


class SalesReportPage extends StatefulWidget {
  const SalesReportPage({Key? key}) : super(key: key);

  @override
  _SalesReportPageState createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = false;
  bool showReport = false;
  List<Map<String, dynamic>> filteredData = [];
  TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> salesData = [
    {
      'location': 'Colombo',
      'businessType': 'Retail',
      'totalSales': 250000.0,
      'cash': 100000.0,
      'card': 100000.0,
      'credit': 30000.0,
      'advance': 20000.0,
    },
    {
      'location': 'Kandy',
      'businessType': 'Wholesale',
      'totalSales': 350000.0,
      'cash': 150000.0,
      'card': 150000.0,
      'credit': 25000.0,
      'advance': 25000.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    filteredData = List.from(salesData);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2A2359), // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Calendar text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2A2359), // Button text color
              ),
            ),
            dialogBackgroundColor: Colors.white, // Background color of the dialog
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  Future<void> _generateReport() async {
    if (fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both dates')),
      );
      return;
    }

    if (toDate!.isBefore(fromDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      isLoading = false;
      showReport = true;
    });
  }

  Future<void> _generatePDF() async {
    setState(() => isLoading = true);
    try {
      final imageBytes = await rootBundle.load('assets/images/skynet_pro.jpg');
      final image = pw.MemoryImage(
        imageBytes.buffer.asUint8List(),
      );
      final pdf = pw.Document();
      final page = pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header section with logo and date
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Image(
                        image,
                        width: 150, // Set your desired width
                        fit: pw.BoxFit.contain,
                      ),
                    ],
                  ),
                  pw.Text(
                    'From : ${DateFormat('yyyy-MM-dd').format(fromDate!)} To : ${DateFormat('yyyy-MM-dd').format(toDate!)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'SKYNET Pro Sales Reports',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey), // Add borders
                columnWidths: {
                  0: const pw.FlexColumnWidth(2), // Location
                  1: const pw.FlexColumnWidth(2), // Business Type
                  2: const pw.FlexColumnWidth(1.5), // Total Sale
                  3: const pw.FlexColumnWidth(1.5), // Cash
                  4: const pw.FlexColumnWidth(1.5), // Card
                  5: const pw.FlexColumnWidth(1.5), // Credit
                  6: const pw.FlexColumnWidth(1.5), // Advance
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    children: [
                      'Location',
                      'Business Type',
                      'Total Sale',
                      'Cash',
                      'Card',
                      'Credit',
                      'Advance',
                    ]
                        .map((text) => pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                text,
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 11),
                              ),
                            ))
                        .toList(),
                  ),
                  // Seethawaka Regency Section
                  ...[
                    'Alacart',
                    'Delivery',
                    'Room Service',
                    'Food Truck',
                    'Banquet'
                  ].map(
                    (type) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Seethawaka Regency',
                              style: pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(type),
                        ),
                        ...List.generate(
                            5,
                            (index) => pw.Padding(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: pw.Text('10,000.00',
                                      textAlign: pw.TextAlign.right,
                                      style: pw.TextStyle(fontSize: 9)),
                                )),
                      ],
                    ),
                  ),
                  // Seethawaka Income Total
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('INCOME',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('TOTAL',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      ...List.generate(
                          5,
                          (index) => pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  '50,000.00',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 9),
                                  textAlign: pw.TextAlign.right,
                                ),
                              )),
                    ],
                  ),
                  // Empty row as divider
                  pw.TableRow(
                    children: List.generate(
                        7,
                        (index) => pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(''),
                            )),
                  ),
                  // Avissawella Section
                  ...['Restaurant', 'Bar'].map(
                    (type) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Rest House Avissawella',
                              style: pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(type),
                        ),
                        ...List.generate(
                            5,
                            (index) => pw.Padding(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: pw.Text('10,000.00',
                                      textAlign: pw.TextAlign.right,
                                      style: pw.TextStyle(fontSize: 9)),
                                )),
                      ],
                    ),
                  ),
                  // Avissawella Income Total
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('INCOME',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('TOTAL',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      ...List.generate(
                          5,
                          (index) => pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  '20,000.00',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 9),
                                  textAlign: pw.TextAlign.right,
                                ),
                              )),
                    ],
                  ),
                  // Empty row as divider
                  pw.TableRow(
                    children: List.generate(
                        7,
                        (index) => pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(''),
                            )),
                  ),
                  // Grand Total
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('GRAND TOTAL',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('')),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '350,000.00',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      ...List.generate(
                          4,
                          (index) => pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(''),
                              )),
                    ],
                  ),
                ],
              ),
              // Footer
              pw.Spacer(),
              pw.Row(
                children: [
                  pw.Text(
                    'SKYNET Pro',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    ' Powered By Ceylon Innovation',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          );
        },
      );
      pdf.addPage(page);

      // final pdfBytes = await pdf.save();

      await showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PDF Preview', style: GoogleFonts.poppins()),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel', style: GoogleFonts.poppins()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PdfPreview(
                    build: (format) async {
                      final bytes = await pdf.save();

                      try {
                        // Save the PDF file
                        await FileSaver.instance.saveFile(
                            name: 'sales_report.pdf',
                            bytes: bytes,
                            ext: 'pdf',
                            mimeType: MimeType.pdf);

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('PDF saved successfully'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        // Show error message if saving fails
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error saving PDF: $e'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }

                      return bytes;
                    },
                    initialPageFormat: PdfPageFormat.a4,
                    allowPrinting: true,
                    allowSharing: true,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    maxPageWidth: 700,
                    actions: [],
                    onPrinted: (context) => print('Document printed'),
                    onShared: (context) => print('Document shared'),
                    scrollViewDecoration: BoxDecoration(
                      color: Colors.grey.shade200,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        automaticallyImplyLeading: false,
        toolbarHeight: 120,
        flexibleSpace: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 24),
                  label: const Text(
                    'Back',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ),
            ),
            Text(
              'Sales Report',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 33,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From Date',
                              style:
                                  GoogleFonts.poppins(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              fromDate != null
                                  ? DateFormat('yyyy-MM-dd').format(fromDate!)
                                  : 'Select Date',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'To Date',
                              style:
                                  GoogleFonts.poppins(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              toDate != null
                                  ? DateFormat('yyyy-MM-dd').format(toDate!)
                                  : 'Select Date',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _generateReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Generate Report',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
            if (showReport) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: isLoading ? null : _generatePDF,
                icon: const Icon(Icons.download, color: Colors.white),
                label: Text(
                  'Download PDF',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search by location or business type',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    filteredData = salesData
                        .where((data) =>
                            data['location']
                                .toLowerCase()
                                .contains(value.toLowerCase()) ||
                            data['businessType']
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                        .toList();
                  });
                },
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Location')),
                    DataColumn(label: Text('Business Type')),
                    DataColumn(label: Text('Total Sale')),
                    DataColumn(label: Text('Cash')),
                    DataColumn(label: Text('Card')),
                    DataColumn(label: Text('Credit')),
                    DataColumn(label: Text('Advance')),
                  ],
                  rows: [
                    // Seethawaka Regency Section
                    DataRow(cells: [
                      DataCell(Text('Seethawaka Regency')),
                      DataCell(Text('Alacart')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Seethawaka Regency')),
                      DataCell(Text('Delivery')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Seethawaka Regency')),
                      DataCell(Text('Room Service')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Seethawaka Regency')),
                      DataCell(Text('Food Truck')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Seethawaka Regency')),
                      DataCell(Text('Banquet')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                    ]),
                    // Subtotal for Seethawaka
                    DataRow(cells: [
                      DataCell(Text('INCOME',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('TOTAL',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('50,000.00',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('50,000.00',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('50,000.00',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('50,000.00',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('50,000.00',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                    ]),
                    // Add a divider row
                    DataRow(
                        cells: List.generate(7, (index) => DataCell(Text('')))),
                    // Avissawella Section
                    DataRow(cells: [
                      DataCell(Text('Rest House Avissawella')),
                      DataCell(Text('Restaurant')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Rest House Avissawella')),
                      DataCell(Text('Bar')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                      DataCell(Text('10,000.00')),
                    ]),
                    // Subtotal for Avissawella
                    DataRow(cells: [
                      DataCell(Text('INCOME',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('TOTAL',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('20,000.00',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('20,000.00',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('20,000.00',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('20,000.00',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('20,000.00',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                    ]),
                    // Add a divider row
                    DataRow(
                        cells: List.generate(7, (index) => DataCell(Text('')))),
                    // Grand Total
                    DataRow(cells: [
                      DataCell(Text('GRAND TOTAL',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('')),
                      DataCell(Text('350,000.00',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('')),
                      DataCell(Text('')),
                      DataCell(Text('')),
                      DataCell(Text('')),
                    ]),
                  ],
                ),
              )
            ],
          ],
        ),
      ),
    );
  }
}
