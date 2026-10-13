import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:topar_115/core/utils/haptic_utils.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../data/models/topic_model.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AttachmentViewerScreen
/// Rich built-in viewer for Subject attachments (PDF, PPTX, Images).
/// - Images: InteractiveViewer with pinch-zoom
/// - PDF (base64): WebView with embedded base64 data URI
/// - PDF (URL): WebView loading the URL directly
/// - PPTX: Info card + option to open externally (can't render natively)
/// ─────────────────────────────────────────────────────────────────────────────
class AttachmentViewerScreen extends StatefulWidget {
  final TopicAttachment attachment;
  final String topicTitle;

  const AttachmentViewerScreen({
    super.key,
    required this.attachment,
    required this.topicTitle,
  });

  @override
  State<AttachmentViewerScreen> createState() => _AttachmentViewerScreenState();
}

class _AttachmentViewerScreenState extends State<AttachmentViewerScreen> {
  bool _isDarkMode = true;
  bool _isLoading = true;
  final TransformationController _transformController = TransformationController();
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    final att = widget.attachment;
    if (_needsWebView(att)) {
      _initWebView(att);
    }
  }

  bool _needsWebView(TopicAttachment att) {
    return att.isPdf; // Only PDF uses WebView for real rendering
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  // ── Init WebView for PDF ──────────────────────────────────────────────────
  void _initWebView(TopicAttachment att) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          if (mounted) setState(() => _isLoading = false);
        },
        onWebResourceError: (error) {
          if (mounted) setState(() => _isLoading = false);
        },
      ));

    final raw = att.urlOrData.trim();

    if (raw.startsWith('data:application/pdf') && raw.contains('base64,')) {
      // Embedded base64 PDF → create HTML with embedded object
      final base64Data = raw.split('base64,').last;
      final html = _buildPdfHtml(base64Data);
      controller.loadHtmlString(html, baseUrl: null);
    } else if (raw.startsWith('https://') || raw.startsWith('http://')) {
      // Server URL → load directly in WebView
      controller.loadRequest(Uri.parse(raw));
    } else {
      setState(() => _isLoading = false);
    }

    setState(() => _webViewController = controller);
  }

  String _buildPdfHtml(String base64Data) {
    return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { background: #0f172a; width: 100%; height: 100vh; overflow: hidden; }
  embed, object { width: 100%; height: 100vh; border: none; }
</style>
</head>
<body>
<embed src="data:application/pdf;base64,$base64Data" type="application/pdf" width="100%" height="100%">
<object data="data:application/pdf;base64,$base64Data" type="application/pdf" width="100%" height="100%">
  <p style="color:white;text-align:center;padding:40px;">
    PDF görnükleri ýüklenýär... ýa-da daşarky programma ulanyň.
  </p>
</object>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    final att = widget.attachment;

    return Theme(
      data: _isDarkMode ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true),
      child: Scaffold(
        backgroundColor: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                att.name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${att.type.toUpperCase()} • ${att.size}',
                style: TextStyle(
                  fontSize: 11,
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              tooltip: _isDarkMode ? 'Açyk rejim' : 'Garaňky rejim',
              onPressed: () {
                HapticUtils.light();
                setState(() => _isDarkMode = !_isDarkMode);
              },
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              tooltip: 'Faýl adyny göçür',
              onPressed: () {
                HapticUtils.light();
                Clipboard.setData(ClipboardData(
                  text: '${att.name} — ${widget.topicTitle}',
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${att.name} maglumaty göçürildi 📋'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: att.isImage
              ? _buildImageViewer(att)
              : att.isPdf
                  ? _buildPdfViewer(att)
                  : _buildPptxViewer(att),
        ),
      ),
    );
  }

  // ── Image Viewer ─────────────────────────────────────────────────────────
  Widget _buildImageViewer(TopicAttachment att) {
    Widget imageWidget;
    final raw = att.urlOrData.trim();

    if (raw.startsWith('data:image') && raw.contains('base64,')) {
      final base64Str = raw.split('base64,').last;
      try {
        final bytes = base64Decode(base64Str);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildErrorCard(att),
        );
      } catch (_) {
        imageWidget = _buildErrorCard(att);
      }
    } else if (raw.startsWith('http://') || raw.startsWith('https://')) {
      imageWidget = Image.network(
        raw,
        fit: BoxFit.contain,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorCard(att),
      );
    } else {
      imageWidget = _buildErrorCard(att);
    }

    return Stack(
      children: [
        Center(
          child: InteractiveViewer(
            transformationController: _transformController,
            minScale: 0.8,
            maxScale: 5.0,
            child: imageWidget,
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.small(
            backgroundColor: _isDarkMode ? const Color(0xFF334155) : Colors.white,
            foregroundColor: _isDarkMode ? Colors.white : Colors.black87,
            elevation: 4,
            tooltip: 'Ölçegi dikelt',
            onPressed: () {
              HapticUtils.light();
              _resetZoom();
            },
            child: const Icon(Icons.center_focus_strong_rounded),
          ),
        ),
      ],
    );
  }

  // ── PDF Viewer (WebView) ──────────────────────────────────────────────────
  Widget _buildPdfViewer(TopicAttachment att) {
    final raw = att.urlOrData.trim();
    final hasContent = raw.isNotEmpty &&
        (raw.startsWith('data:') || raw.startsWith('http'));

    if (!hasContent || _webViewController == null) {
      return _buildNoContentCard(att);
    }

    return Stack(
      children: [
        WebViewWidget(controller: _webViewController!),
        if (_isLoading)
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                Gap(16),
                Text(
                  'PDF ýüklenýär...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── PPTX Viewer (info card — can't render natively) ───────────────────────
  Widget _buildPptxViewer(TopicAttachment att) {
    final raw = att.urlOrData.trim();
    final hasUrl = raw.startsWith('http://') || raw.startsWith('https://');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEA580C).withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.slideshow_rounded,
                size: 64,
                color: Color(0xFFEA580C),
              ),
            ),
            const Gap(24),
            Text(
              att.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              '${att.size} • PowerPoint Faýl',
              style: TextStyle(
                fontSize: 13,
                color: _isDarkMode ? Colors.white54 : Colors.black54,
              ),
            ),
            const Gap(32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFEA580C)),
                      const Gap(10),
                      Expanded(
                        child: Text(
                          hasUrl
                              ? 'Bu faýl serwerde saklanýar. Aşakdaky düwmä basyp göçürip alyp, daşarky programma bilen açyp bilersiňiz.'
                              : 'PowerPoint faýllary programmanyň içinde görkezilip bilinmez. Faýly göçürip, Microsoft PowerPoint ýa-da başga programma bilen açyň.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: _isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (hasUrl) ...[
              const Gap(20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Göçürip al / Daşarky açmak'),
                onPressed: () {
                  HapticUtils.medium();
                  // Copy URL to clipboard so user can open it
                  Clipboard.setData(ClipboardData(text: raw));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('📎 Faýl URL-i göçürildi! Brauzere ýa-da başga programma ýapyşdyryp açyň.'),
                      backgroundColor: const Color(0xFFEA580C),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(TopicAttachment att) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.broken_image_outlined, size: 64, color: Colors.blueAccent),
          ),
          const Gap(16),
          Text(att.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Gap(4),
          Text('${att.size} • Görkezilmedi', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNoContentCard(TopicAttachment att) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: _isDarkMode ? Colors.white38 : Colors.black26,
            ),
            const Gap(16),
            Text(
              'Bu faýl başga enjamdan üstünlikli görünmez.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: _isDarkMode ? Colors.white54 : Colors.black54,
              ),
            ),
            const Gap(8),
            Text(
              att.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
