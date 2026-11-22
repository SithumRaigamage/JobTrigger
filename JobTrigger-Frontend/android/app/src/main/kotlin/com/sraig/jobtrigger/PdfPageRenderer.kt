package com.sraig.jobtrigger

import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.system.Os
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import kotlin.concurrent.thread

/**
 * US-STU-02: draws a PDF's pages to PNGs in memory for the super admin's
 * review screen (lib/core/platform/pdf_page_renderer.dart). PdfRenderer
 * needs a seekable file descriptor; an anonymous memfd (Android 11+) is one
 * that lives only in memory, so the document never touches disk. Older
 * Android answers "unsupported" and the app points to the website.
 */
object PdfPageRenderer {
    private const val CHANNEL = "jobtrigger/pdf"

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "renderPages") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val bytes = call.argument<ByteArray>("bytes")
            val maxPages = call.argument<Int>("maxPages") ?: 10
            val width = call.argument<Int>("width") ?: 1200
            if (bytes == null) {
                result.error("bad_args", null, null)
                return@setMethodCallHandler
            }
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
                result.error("unsupported", null, null)
                return@setMethodCallHandler
            }
            val main = Handler(Looper.getMainLooper())
            thread(name = "pdf-render") {
                val pages = try {
                    render(bytes, maxPages, width)
                } catch (e: Exception) {
                    null
                }
                main.post {
                    if (pages == null) result.error("unreadable", null, null) else result.success(pages)
                }
            }
        }
    }

    // Only called after the SDK check in register (memfd_create is API 30).
    @android.annotation.TargetApi(Build.VERSION_CODES.R)
    private fun render(bytes: ByteArray, maxPages: Int, width: Int): List<ByteArray>? {
        val fd = Os.memfd_create("student-document", 0)
        try {
            // Os.write, not a FileOutputStream: closing that would close the fd.
            var written = 0
            while (written < bytes.size) {
                written += Os.write(fd, bytes, written, bytes.size - written)
            }
            Os.lseek(fd, 0, android.system.OsConstants.SEEK_SET)
            ParcelFileDescriptor.dup(fd).use { pfd ->
                PdfRenderer(pfd).use { renderer ->
                    val pages = mutableListOf<ByteArray>()
                    for (index in 0 until minOf(renderer.pageCount, maxOf(1, maxPages))) {
                        renderer.openPage(index).use { page ->
                            val height = (width.toLong() * page.height / maxOf(1, page.width)).toInt()
                            val bitmap = Bitmap.createBitmap(width, maxOf(1, height), Bitmap.Config.ARGB_8888)
                            bitmap.eraseColor(Color.WHITE)
                            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                            val out = ByteArrayOutputStream()
                            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                            bitmap.recycle()
                            pages.add(out.toByteArray())
                        }
                    }
                    return pages.ifEmpty { null }
                }
            }
        } finally {
            Os.close(fd)
        }
    }
}
