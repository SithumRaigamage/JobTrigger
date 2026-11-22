package com.sraig.jobtrigger

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// A FragmentActivity: local_auth's BiometricPrompt needs one (US-JX-21).
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // US-STU-02: in-memory PDF pages for the student review screen.
        PdfPageRenderer.register(flutterEngine.dartExecutor.binaryMessenger)
    }
}
