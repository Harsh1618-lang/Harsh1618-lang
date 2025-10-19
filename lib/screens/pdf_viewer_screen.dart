import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../main.dart';

class PDFViewerScreen extends ConsumerStatefulWidget {
  final String pdfUrl;
  final String title;

  const PDFViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  ConsumerState<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends ConsumerState<PDFViewerScreen> {
  PdfControllerPinch? _pdfController;
  bool _isLoading = true;
  String? _error;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _pdfController = PdfControllerPinch(
        document: PdfDocument.openData(
          // Download PDF data from URL
          await _downloadPDFData(widget.pdfUrl),
        ),
      );

      setState(() => _isLoading = false);

      // Log analytics
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      if (user != null) {
        ref.read(storageServiceProvider).logPDFView(
              userId: user.uid,
              courseId: 'unknown', // TODO: Pass courseId from navigation
              pdfUrl: widget.pdfUrl,
            );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load PDF: $e';
      });
    }
  }

  Future<List<int>> _downloadPDFData(String url) async {
    final response = await HttpClient()
        .getUrl(Uri.parse(url))
        .then((request) => request.close())
        .then((response) => response.toList())
        .then((data) => data.expand((x) => x).toList());
    return response;
  }

  Future<void> _downloadPDF() async {
    setState(() => _isDownloading = true);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = widget.title.replaceAll(RegExp(r'[^\w\s-]'), '');
      final filePath = '${dir.path}/$fileName.pdf';

      await ref.read(storageServiceProvider).downloadFile(
            url: widget.pdfUrl,
            localPath: filePath,
            onProgress: (progress) {
              setState(() => _downloadProgress = progress);
            },
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded to: $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (!_isLoading && _error == null)
            IconButton(
              icon: _isDownloading
                  ? CircularProgressIndicator(
                      value: _downloadProgress,
                      color: Colors.white,
                    )
                  : const Icon(Icons.download),
              onPressed: _isDownloading ? null : _downloadPDF,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPDF,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return PdfViewPinch(
      controller: _pdfController!,
      padding: 10,
      backgroundDecoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
    );
  }
}
