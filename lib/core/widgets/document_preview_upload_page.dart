import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/api.dart';
import '../../api/document_upload_service.dart';
import '../theme.dart';
import 'circular_back_button.dart';

/// Full-screen preview page for inspecting a document before uploading or viewing.
/// Features a document preview area and two action buttons: [Cancel] and [Upload].
class DocumentPreviewUploadPage extends StatefulWidget {
  final String fileName;
  final String? filePath;
  final Uint8List? fileBytes;
  final int? fileSize;
  final String? fileUrl;
  final DocumentUploadService? uploadService;
  final Future<String?> Function()? onUpload;
  final dynamic bookingId;

  const DocumentPreviewUploadPage({
    super.key,
    required this.fileName,
    this.filePath,
    this.fileBytes,
    this.fileSize,
    this.fileUrl,
    this.uploadService,
    this.onUpload,
    this.bookingId,
  });

  @override
  State<DocumentPreviewUploadPage> createState() =>
      _DocumentPreviewUploadPageState();
}

class _DocumentPreviewUploadPageState extends State<DocumentPreviewUploadPage> {
  Uint8List? _bytes;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bytes = widget.fileBytes;
    if (_bytes == null && widget.filePath != null && !kIsWeb) {
      _loadLocalBytes();
    }
  }

  Future<void> _loadLocalBytes() async {
    try {
      final file = File(widget.filePath!);
      if (await file.exists()) {
        final data = await file.readAsBytes();
        if (mounted) {
          setState(() => _bytes = data);
        }
      }
    } catch (e) {
      debugPrint('Error loading local file bytes: $e');
    }
  }

  bool get _isImage {
    final lower = widget.fileName.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  bool get _isPdf {
    return widget.fileName.toLowerCase().endsWith('.pdf');
  }

  String get _formattedFileSize {
    final size = widget.fileSize ?? (_bytes?.length ?? 0);
    if (size <= 0) return '';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _handleUpload() async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      String? uploadedUrl;

      if (widget.onUpload != null) {
        uploadedUrl = await widget.onUpload!();
      } else {
        final service = widget.uploadService ?? DocumentUploadService();
        uploadedUrl = await service.uploadFile(
          fileName: widget.fileName,
          bytes: _bytes,
          filePath: widget.filePath,
          bookingId: widget.bookingId,
        );
      }

      if (!mounted) return;

      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        Navigator.of(context).pop(uploadedUrl);
      } else {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Failed to upload document. Please try again.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload document. Please try again.'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorMessage = 'Upload error: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload error: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? AppDarkColors.scaffoldBackground : const Color(0xFFF8FAFC);
    final cardBg =
        isDark ? AppDarkColors.surfaceCard : AppColors.surfaceWhite;
    final primaryText =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    final subtitleText =
        isDark ? AppDarkColors.textSubtitle : AppColors.textSubtitle;
    final borderColor =
        isDark ? AppDarkColors.border : const Color(0xFFE2E8F0);
    final isUploadMode = widget.fileUrl == null;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 58,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: CircularBackButton(
              onBack: () => Navigator.of(context).pop(null),
            ),
          ),
        ),
        title: Text(
          isUploadMode ? 'Upload Document Preview' : 'Document Preview',
          style: TextStyle(
            fontFamily: 'Helvetica Neue',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: primaryText,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Preview body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Preview Card
                    Container(
                      constraints: const BoxConstraints(minHeight: 280),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildPreviewContent(
                        isDark: isDark,
                        primaryText: primaryText,
                        subtitleText: subtitleText,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // File Information Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: _isPdf
                                      ? const Color(0xFFFEF2F2)
                                      : (_isImage
                                          ? const Color(0xFFEFF6FF)
                                          : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _isPdf
                                      ? Icons.picture_as_pdf_rounded
                                      : (_isImage
                                          ? Icons.image_rounded
                                          : Icons.description_rounded),
                                  color: _isPdf
                                      ? const Color(0xFFEF4444)
                                      : (_isImage
                                          ? const Color(0xFF3B82F6)
                                          : const Color(0xFF64748B)),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.fileName,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: primaryText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formattedFileSize.isNotEmpty
                                          ? '${_isPdf ? "PDF Document" : (_isImage ? "Image File" : "Document")} • $_formattedFileSize'
                                          : (_isPdf
                                              ? 'PDF Document'
                                              : (_isImage
                                                  ? 'Image File'
                                                  : 'Document')),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: subtitleText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (isUploadMode) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: subtitleText,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Review the document above. Tap "Upload" to upload and attach this file.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subtitleText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 18,
                              color: Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Buttons (Cancel & Upload)
            if (isUploadMode)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border(top: BorderSide(color: borderColor)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 1. Cancel Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _isUploading
                              ? null
                              : () => Navigator.of(context).pop(null),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? AppDarkColors.border
                                  : const Color(0xFFCBD5E1),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Helvetica Neue',
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 2. Upload Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _handleUpload,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.whatsappGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            disabledBackgroundColor:
                                AppColors.whatsappGreen.withValues(alpha: 0.6),
                          ),
                          child: _isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 19,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Upload',
                                      style: TextStyle(
                                        fontFamily: 'Helvetica Neue',
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent({
    required bool isDark,
    required Color primaryText,
    required Color subtitleText,
  }) {
    // If it's an image and we have bytes
    if (_isImage && _bytes != null) {
      return Container(
        height: 380,
        color: isDark ? Colors.black26 : const Color(0xFFF1F5F9),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: Image.memory(
              _bytes!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => _buildPlaceholderFallback(
                isDark: isDark,
                primaryText: primaryText,
                subtitleText: subtitleText,
              ),
            ),
          ),
        ),
      );
    }

    // If it's a remote image URL
    if (_isImage && widget.fileUrl != null) {
      final fullUrl = widget.fileUrl!.startsWith('http')
          ? widget.fileUrl!
          : '${ApiConfig.baseUrl}${widget.fileUrl}';

      return Container(
        height: 380,
        color: isDark ? Colors.black26 : const Color(0xFFF1F5F9),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: Image.network(
              fullUrl,
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.whatsappGreen,
                  ),
                );
              },
              errorBuilder: (_, _, _) => _buildPlaceholderFallback(
                isDark: isDark,
                primaryText: primaryText,
                subtitleText: subtitleText,
              ),
            ),
          ),
        ),
      );
    }

    // PDF, DOC, or Document Card Preview
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _isPdf
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _isPdf
                    ? Icons.picture_as_pdf_rounded
                    : Icons.description_rounded,
                size: 42,
                color: _isPdf
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.fileName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isPdf ? 'PDF Document' : 'Document File',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: subtitleText,
            ),
          ),
          if (_formattedFileSize.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _formattedFileSize,
              style: TextStyle(
                fontSize: 12,
                color: subtitleText,
              ),
            ),
          ],
          if (widget.fileUrl != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final url = widget.fileUrl!.startsWith('http')
                      ? widget.fileUrl!
                      : '${ApiConfig.baseUrl}${widget.fileUrl}';
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } catch (_) {}
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Open Externally'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.whatsappGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderFallback({
    required bool isDark,
    required Color primaryText,
    required Color subtitleText,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 54, color: subtitleText),
          const SizedBox(height: 12),
          Text(
            widget.fileName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryText,
            ),
          ),
        ],
      ),
    );
  }
}
