// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdf_page_renderer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pdfPageRenderer)
final pdfPageRendererProvider = PdfPageRendererProvider._();

final class PdfPageRendererProvider
    extends
        $FunctionalProvider<PdfPageRenderer, PdfPageRenderer, PdfPageRenderer>
    with $Provider<PdfPageRenderer> {
  PdfPageRendererProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pdfPageRendererProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pdfPageRendererHash();

  @$internal
  @override
  $ProviderElement<PdfPageRenderer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PdfPageRenderer create(Ref ref) {
    return pdfPageRenderer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PdfPageRenderer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PdfPageRenderer>(value),
    );
  }
}

String _$pdfPageRendererHash() => r'82c7b6282c86022b48872709ba2e85e2ce2d6e25';
