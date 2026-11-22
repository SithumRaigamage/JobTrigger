import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pdf_page_renderer.g.dart';

/// US-STU-02: draws a PDF's pages to PNG images **in memory** so the super
/// admin can read an uploaded student document without it touching disk.
/// No package (CLAUDE.md §3): a small platform channel, `jobtrigger/pdf`,
/// answered by `ios/Runner/PdfPageRenderer.swift` (PDFKit, from `Data`)
/// and `android/.../PdfPageRenderer.kt` (`PdfRenderer` over an anonymous
/// `memfd`, Android 11+).
abstract class PdfPageRenderer {
  /// PNG bytes for up to [maxPages] pages, [width] pixels wide. Null when
  /// this device can't draw PDFs in memory (older Android) or the file is
  /// not a readable PDF.
  Future<List<Uint8List>?> render(
    Uint8List pdf, {
    int maxPages = 10,
    int width = 1200,
  });
}

class MethodChannelPdfPageRenderer implements PdfPageRenderer {
  const MethodChannelPdfPageRenderer();

  static const _channel = MethodChannel('jobtrigger/pdf');

  @override
  Future<List<Uint8List>?> render(
    Uint8List pdf, {
    int maxPages = 10,
    int width = 1200,
  }) async {
    try {
      final pages = await _channel.invokeListMethod<Uint8List>('renderPages', {
        'bytes': pdf,
        'maxPages': maxPages,
        'width': width,
      });
      return pages == null || pages.isEmpty ? null : pages;
    } on PlatformException catch (error) {
      // Never logs the document, only that drawing it failed.
      debugPrint('PDF render failed: ${error.code}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

@riverpod
PdfPageRenderer pdfPageRenderer(Ref ref) =>
    const MethodChannelPdfPageRenderer();
