import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfViewerScreen extends StatelessWidget {
  final String pdfUrl;
  final String pdfName;

  const PdfViewerScreen(
      {super.key, required this.pdfUrl, required this.pdfName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(pdfName),
          centerTitle: true,
        ),
        body: PdfViewer.uri(Uri.parse(pdfUrl)));
  }
}
