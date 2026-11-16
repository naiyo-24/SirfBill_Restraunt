import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/procurement_api_service.dart';

class VendorInvoiceAttachmentBox extends StatefulWidget {
  final String? initialUrl;
  final bool isDark;
  final ValueChanged<String?> onAttachmentChanged;

  const VendorInvoiceAttachmentBox({
    super.key,
    this.initialUrl,
    required this.isDark,
    required this.onAttachmentChanged,
  });

  @override
  State<VendorInvoiceAttachmentBox> createState() => _VendorInvoiceAttachmentBoxState();
}

class _VendorInvoiceAttachmentBoxState extends State<VendorInvoiceAttachmentBox> {
  String? _documentUrl;
  String? _fileName;
  Uint8List? _previewBytes;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _documentUrl = widget.initialUrl;
    if (_documentUrl != null && _documentUrl!.isNotEmpty) {
      _fileName = _documentUrl!.split('/').last;
    }
  }

  Future<void> _uploadBytes(Uint8List bytes, String filename) async {
    setState(() => _isUploading = true);
    try {
      final url = await ProcurementApiService.uploadVendorInvoiceDocument(
        bytes: bytes,
        filename: filename,
      );

      if (mounted) {
        if (url != null && url.isNotEmpty) {
          setState(() {
            _documentUrl = url;
            _fileName = filename;
            _previewBytes = filename.toLowerCase().endsWith('.pdf') ? null : bytes;
          });
          widget.onAttachmentChanged(url);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vendor bill attached: $filename'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload invoice document'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _captureFromCamera() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      if (bytes.isEmpty) return;

      final extension = photo.name.contains('.') ? photo.name.split('.').last : 'jpg';
      final filename = 'bill_camera_${DateTime.now().millisecondsSinceEpoch}.$extension';
      await _uploadBytes(bytes, filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read file data'), backgroundColor: Colors.red),
          );
        }
        return;
      }
      await _uploadBytes(file.bytes!, file.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picker error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeAttachment() {
    setState(() {
      _documentUrl = null;
      _fileName = null;
      _previewBytes = null;
    });
    widget.onAttachmentChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    if (_isUploading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6))),
            SizedBox(width: 10),
            Text('Uploading digital vendor invoice...', style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6))),
          ],
        ),
      );
    }

    if (_documentUrl != null && _documentUrl!.isNotEmpty) {
      final isPdf = _fileName?.toLowerCase().endsWith('.pdf') ?? false;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            if (_previewBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.memory(_previewBytes!, width: 36, height: 36, fit: BoxFit.cover),
              )
            else
              Icon(isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded, size: 24, color: const Color(0xFF10B981)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('DIGITAL VENDOR INVOICE ATTACHED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                  Text(_fileName ?? 'Invoice document', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _captureFromCamera,
              icon: const Icon(Icons.photo_camera_rounded, size: 14, color: Color(0xFF10B981)),
              label: const Text('Retake', style: TextStyle(fontSize: 11, color: Color(0xFF10B981))),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
              tooltip: 'Remove Attachment',
              onPressed: _removeAttachment,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _captureFromCamera,
          icon: const Icon(Icons.photo_camera_rounded, size: 16),
          label: const Text('Take Photo of Bill (Camera)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.upload_file_rounded, size: 16, color: Color(0xFF3B82F6)),
          label: const Text('Upload PDF / File', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6))),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        Text(
          'Snap bill on tablet/mobile or upload PDF',
          style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}
