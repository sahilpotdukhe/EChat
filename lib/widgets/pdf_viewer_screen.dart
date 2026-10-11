import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shadcn_kit/shadcn_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows a PDF in the app, with "page 3 of 12" under the title and a button
/// to open it in another app instead.
class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String pdfName;

  const PdfViewerScreen({super.key, required this.pdfUrl, required this.pdfName});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int? _page;
  int? _pageCount;

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.pdfUrl);
    var opened = false;
    try {
      if (uri != null) opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Reported below.
    }
    if (!opened && mounted) {
      showShadcnToast(context,
          title: 'Couldn\'t open this PDF',
          description: 'No app on this phone can open it.',
          variant: ShadcnToastVariant.destructive);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.shadcn;
    final uri = Uri.tryParse(widget.pdfUrl);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.pdfName, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.foreground)),
            if (_pageCount != null)
              Text('Page ${_page ?? 1} of $_pageCount',
                  style: TextStyle(fontSize: 12, color: t.mutedForeground)),
          ],
        ),
        actions: [
          ShadcnButton(
            variant: ShadcnButtonVariant.ghost,
            size: ShadcnButtonSize.icon,
            tooltip: 'Open in another app',
            semanticLabel: 'Open in another app',
            onPressed: _openExternally,
            child: const Icon(Icons.open_in_new_rounded, size: 22),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: uri == null || widget.pdfUrl.isEmpty
          ? _error()
          : PdfViewer.uri(
              uri,
              params: PdfViewerParams(
                backgroundColor: t.muted,
                onViewerReady: (document, _) => setState(() => _pageCount = document.pages.length),
                onPageChanged: (page) => setState(() => _page = page),
                loadingBannerBuilder: (context, downloaded, total) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          value: total == null || total == 0 ? null : downloaded / total,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ShadcnText(
                        total == null || total == 0
                            ? 'Opening PDF…'
                            : 'Downloading… ${(downloaded * 100 / total).round()}%',
                        variant: ShadcnTextVariant.muted,
                      ),
                    ],
                  ),
                ),
                errorBannerBuilder: (context, error, stackTrace, ref) => _error(),
              ),
            ),
    );
  }

  Widget _error() => ShadcnEmptyState(
        icon: Icons.picture_as_pdf_outlined,
        title: 'Couldn\'t open this PDF',
        description: 'It may have been removed, or your connection dropped. '
            'You can try opening it in another app.',
        action: ShadcnButton(
          variant: ShadcnButtonVariant.outline,
          leading: const Icon(Icons.open_in_new_rounded),
          onPressed: _openExternally,
          child: const Text('Open in another app'),
        ),
      );
}
