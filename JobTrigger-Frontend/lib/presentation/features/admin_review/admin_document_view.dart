import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../common_widgets/inline_alert.dart';
import 'admin_application_notifier.dart';

/// US-STU-02: the uploaded student ID or letter. The bytes live only in
/// [adminDocumentProvider] (auto-disposed with the screen). Images are drawn
/// with [Image.memory] and evicted from the in-memory image cache when this
/// view goes; no disk cache is involved anywhere.
class AdminDocumentView extends ConsumerStatefulWidget {
  const AdminDocumentView({super.key, required this.id});

  final String id;

  @override
  ConsumerState<AdminDocumentView> createState() => _AdminDocumentViewState();
}

class _AdminDocumentViewState extends ConsumerState<AdminDocumentView> {
  /// MemoryImage compares by the bytes' identity, so a rebuild adds nothing.
  final _shown = <MemoryImage>{};

  @override
  void dispose() {
    for (final image in _shown) {
      image.evict();
    }
    super.dispose();
  }

  Widget _image(Uint8List bytes, String label) {
    final image = MemoryImage(bytes);
    _shown.add(image);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image(
        image: image,
        semanticLabel: label,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final document = ref.watch(adminDocumentProvider(widget.id));
    return switch (document) {
      AsyncData(value: AdminDocumentImage(:final bytes)) => _image(
        bytes,
        "The student's uploaded document",
      ),
      AsyncData(value: AdminDocumentPdf(:final pages)) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < pages.length; i++) ...[
            _image(pages[i], 'Page ${i + 1} of the uploaded PDF'),
            const SizedBox(height: 8),
          ],
        ],
      ),
      AsyncData(value: AdminDocumentUnreadable()) => const Text(
        "This PDF can't be shown on this phone. Open the application on the "
        'website to read it.',
      ),
      AsyncData(value: AdminDocumentDeleted()) => const Text(
        'Deleted 30 days after the decision. Only a fingerprint is kept.',
      ),
      AsyncError(:final error) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InlineAlert(
            message: error is AppFailure
                ? error.message
                : "Couldn't load the document.",
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => ref.invalidate(adminDocumentProvider(widget.id)),
            child: const Text('Try again'),
          ),
        ],
      ),
      _ => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}
