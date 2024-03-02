import 'package:easy_pdf_viewer/easy_pdf_viewer.dart';
import 'package:flutter/material.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String pdfName;

  const PdfViewerScreen(
      {super.key, required this.pdfUrl, required this.pdfName});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  PDFDocument? pdfDocument;

  @override
  void initState() {
    initializePDF();
    // TODO: implement initState
    super.initState();
  }

  void initializePDF() async {
    pdfDocument = await PDFDocument.fromURL(widget.pdfUrl);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.pdfName),
          centerTitle: true,
        ),
        body: (pdfDocument != null)
            ? PDFViewer(
                document: pdfDocument!,
              )
            : Center(
                child: CircularProgressIndicator(),
              ));
  }
}
