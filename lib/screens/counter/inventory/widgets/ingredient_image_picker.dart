import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../config/api_constants.dart';
import '../services/inventory_api_service.dart';

enum _PickerMode { file, link }

class IngredientImagePicker extends StatefulWidget {
  final String? initialImageUrl;
  final ValueChanged<String?> onImageChanged;

  const IngredientImagePicker({
    super.key,
    this.initialImageUrl,
    required this.onImageChanged,
  });

  @override
  State<IngredientImagePicker> createState() => _IngredientImagePickerState();
}

class _IngredientImagePickerState extends State<IngredientImagePicker> {
  _PickerMode _mode = _PickerMode.file;
  late final TextEditingController _linkController;
  String? _currentImageUrl;
  Uint8List? _previewBytes;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.initialImageUrl;
    _linkController = TextEditingController(text: widget.initialImageUrl ?? '');
    if (_currentImageUrl != null &&
        (_currentImageUrl!.startsWith('http://') || _currentImageUrl!.startsWith('https://'))) {
      _mode = _PickerMode.link;
    }
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  String _resolveFullUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/+$'), '');
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      if (trimmed.startsWith(base)) return trimmed;
      return '$base/api/restaurant/inventory/proxy-image?url=${Uri.encodeComponent(trimmed)}';
    }
    final clean = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$clean';
  }

  Future<void> _pickAndUploadFile() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() => _errorMessage = 'Could not read file data');
        return;
      }

      setState(() {
        _isUploading = true;
        _previewBytes = bytes;
      });

      final uploadedUrl = await InventoryApiService.uploadIngredientImage(bytes, file.name);

      if (uploadedUrl != null && mounted) {
        setState(() {
          _currentImageUrl = uploadedUrl;
          _linkController.text = uploadedUrl;
          _isUploading = false;
        });
        widget.onImageChanged(uploadedUrl);
      } else if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Failed to upload image to server';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _onLinkChanged(String val) {
    final trimmed = val.trim();
    setState(() {
      _currentImageUrl = trimmed.isNotEmpty ? trimmed : null;
      _previewBytes = null;
      _errorMessage = null;
    });
    widget.onImageChanged(trimmed.isNotEmpty ? trimmed : null);
  }

  Future<void> _uploadFromLink() async {
    final link = _linkController.text.trim();
    if (link.isEmpty || (!link.startsWith('http://') && !link.startsWith('https://'))) {
      setState(() => _errorMessage = 'Please enter a valid link starting with http:// or https://');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final uploadedUrl = await InventoryApiService.uploadIngredientFromUrl(link);
      if (uploadedUrl != null && mounted) {
        setState(() {
          _currentImageUrl = uploadedUrl;
          _linkController.text = uploadedUrl;
          _isUploading = false;
        });
        widget.onImageChanged(uploadedUrl);
      } else if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Could not download image from link';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _clearImage() {
    setState(() {
      _currentImageUrl = null;
      _previewBytes = null;
      _linkController.clear();
      _errorMessage = null;
    });
    widget.onImageChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage = _previewBytes != null || (_currentImageUrl != null && _currentImageUrl!.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image_outlined, size: 16, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              const Text(
                'Ingredient Image',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              // Segmented option switcher
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeButton(
                      mode: _PickerMode.file,
                      label: 'Upload File',
                      icon: Icons.file_upload_outlined,
                      isDark: isDark,
                    ),
                    _buildModeButton(
                      mode: _PickerMode.link,
                      label: 'Image Link',
                      icon: Icons.link_rounded,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_mode == _PickerMode.file) ...[
            if (!hasImage)
              InkWell(
                onTap: _isUploading ? null : _pickAndUploadFile,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 72,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: _isUploading
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                              ),
                              SizedBox(width: 10),
                              Text('Uploading image...', style: TextStyle(fontSize: 12)),
                            ],
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_upload_outlined, color: Color(0xFF10B981), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Click to browse & upload image from device',
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _linkController,
                    onChanged: _onLinkChanged,
                    onFieldSubmitted: (_) => _uploadFromLink(),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'https://example.com/images/ingredient.png',
                      hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                      prefixIcon: const Icon(Icons.link, size: 16),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadFromLink,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_download_outlined, size: 16),
                  label: Text(_isUploading ? 'Uploading...' : 'Upload Link', style: const TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
          if (hasImage) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    child: _previewBytes != null
                        ? Image.memory(_previewBytes!, fit: BoxFit.cover)
                        : Image.network(
                            _resolveFullUrl(_currentImageUrl!),
                            fit: BoxFit.cover,
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image, size: 22, color: Colors.grey),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _previewBytes != null ? 'Uploaded image ready' : 'Image loaded',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentImageUrl ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                if (_mode == _PickerMode.file)
                  TextButton.icon(
                    onPressed: _isUploading ? null : _pickAndUploadFile,
                    icon: const Icon(Icons.swap_horiz, size: 14),
                    label: const Text('Change', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                IconButton(
                  onPressed: _clearImage,
                  tooltip: 'Remove Image',
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 11, color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required _PickerMode mode,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _mode == mode;
    return InkWell(
      onTap: () => setState(() => _mode = mode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF334155) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? const Color(0xFF10B981) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
