import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/report_provider.dart';
import 'home_screen.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/stock_transaction.dart';  // Añade esta línea
import 'package:pdf/pdf.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportProvider.notifier).getReport(_startDate, _endDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
      ),
      drawer: HomeScreen.buildDrawer(context),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    child: Text('Desde: ${DateFormat('dd-MM-yyyy').format(_startDate)}'),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                        ref.read(reportProvider.notifier).getReport(_startDate, _endDate);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    child: Text('Hasta: ${DateFormat('dd-MM-yyyy').format(_endDate)}'),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                        ref.read(reportProvider.notifier).getReport(_startDate, _endDate);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (reportData) {
                if (reportData.isEmpty) {
                  return const Center(child: Text('Sin datos para el rango de fechas seleccionado'));
                }
                return ListView.builder(
                  itemCount: reportData.length,
                  itemBuilder: (context, index) {
                    final data = reportData[index];
                    return ExpansionTile(
                      title: Text(data.product.name),
                      subtitle: Text('Entradas: ${data.totalEntradas}, Salidas: ${data.totalSalidas}'),
                      children: data.transactions.map((transaction) {
                        return ListTile(
                          title: Text(transaction.type == TransactionType.entrada ? 'Entrada' : 'Salida'),
                          subtitle: Text('Cantidad: ${transaction.quantity}'),
                          trailing: Text(DateFormat('dd-MM-yyyy').format(transaction.date)),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _exportToPdf(ref),
        child: const Icon(Icons.picture_as_pdf),
      ),
    );
  }

Future<void> _exportToPdf(WidgetRef ref) async {
  final reportData = ref.read(reportProvider).value;
  if (reportData == null) return;

  await Printing.layoutPdf(
    onLayout: (format) async {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              _buildHeader(),
              _buildReportInfo(),
              pw.SizedBox(height: 20),
              _buildSummaryTable(reportData),
              pw.SizedBox(height: 40),
              _buildDetailedReport(reportData),
            ];
          },
          footer: (context) => _buildFooter(context),
        ),
      );

      return pdf.save();
    },
    name: 'inventory_report.pdf',
  );
}

pw.Widget _buildHeader() {
  return pw.Header(
    level: 0,
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Reporte Inventario', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.PdfLogo(),
      ],
    ),
  );
}

pw.Widget _buildReportInfo() {
  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.black),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Reporte Periodo:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('${DateFormat('dd-MM-yyyy').format(_startDate)} a ${DateFormat('dd-MM-yyyy').format(_endDate)}'),
        pw.SizedBox(height: 10),
        pw.Text('Generado:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())),
      ],
    ),
  );
}

pw.Widget _buildSummaryTable(List<ReportData> reportData) {
  return pw.TableHelper.fromTextArray(
    context: null,
    data: <List<String>>[
      <String>['Productos', 'Total Entradas', 'Total Salidas', 'Neto'],
      ...reportData.map((data) => [
        data.product.name,
        data.totalEntradas.toString(),
        data.totalSalidas.toString(),
        (data.totalEntradas - data.totalSalidas).toString(),
      ]),
    ],
    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
    cellAlignments: {
      0: pw.Alignment.centerLeft,
      1: pw.Alignment.centerRight,
      2: pw.Alignment.centerRight,
      3: pw.Alignment.centerRight,
    },
    cellStyle: const pw.TextStyle(fontSize: 10),
  );
}

pw.Widget _buildDetailedReport(List<ReportData> reportData) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('Reporte Detallado', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 10),
      ...reportData.map((data) => _buildProductDetails(data)),
    ],
  );
}

pw.Widget _buildProductDetails(ReportData data) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(data.product.name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 5),
      pw.TableHelper.fromTextArray(
        context: null,
        data: <List<String>>[
          <String>['Fecha', 'Tipo', 'Cantidad'],
          ...data.transactions.map((transaction) => [
            DateFormat('dd-MM-yyyy').format(transaction.date),
            transaction.type == TransactionType.entrada ? 'Entrada' : 'Salida',
            transaction.quantity.toString(),
          ]),
        ],
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellAlignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.center,
          2: pw.Alignment.centerRight,
        },
      ),
      pw.SizedBox(height: 10),
    ],
  );
}

pw.Widget _buildFooter(pw.Context context) {
  return pw.Container(
    alignment: pw.Alignment.centerRight,
    margin: const pw.EdgeInsets.only(top: 1 * PdfPageFormat.cm),
    child: pw.Text(
      'Pagina ${context.pageNumber} of ${context.pagesCount}',
      style: const pw.TextStyle(color: PdfColors.grey),
    ),
  );
}
}