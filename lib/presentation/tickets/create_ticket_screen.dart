import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../../data/datasources/supabase_storage_data_source.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _picker = ImagePicker();

  String _selectedCategory = 'Hardware';
  final List<String> _categories = ['Hardware', 'Software', 'Network', 'Account'];

  TicketPriority _selectedPriority = TicketPriority.medium;

  List<UploadFileData> _selectedFiles = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    final xFile = await _picker.pickImage(source: ImageSource.camera);
    if (xFile == null) return;
    final bytes = await xFile.readAsBytes();
    final ext = xFile.name.split('.').last;
    setState(() => _selectedFiles.add(UploadFileData(bytes: bytes, ext: ext)));
  }

  Future<void> _pickFromGallery() async {
    final xFiles = await _picker.pickMultiImage();
    for (final xFile in xFiles) {
      final bytes = await xFile.readAsBytes();
      final ext = xFile.name.split('.').last;
      setState(() => _selectedFiles.add(UploadFileData(bytes: bytes, ext: ext)));
    }
  }

  Future<void> _pickFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf', 'doc', 'docx'],
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null) continue;
      final ext = file.extension ?? 'file';
      setState(() => _selectedFiles.add(UploadFileData(bytes: bytes, ext: ext)));
    }
  }

  void _showFileSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Tambah Lampiran',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.accentCyan),
                  title: const Text('Kamera'),
                  onTap: () { Navigator.pop(ctx); _pickFromCamera(); },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppTheme.accentCyan),
                  title: const Text('Galeri'),
                  onTap: () { Navigator.pop(ctx); _pickFromGallery(); },
                ),
                ListTile(
                  leading: const Icon(Icons.insert_drive_file_outlined, color: AppTheme.accentCyan),
                  title: const Text('File Manager'),
                  onTap: () { Navigator.pop(ctx); _pickFromFiles(); },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final ticketProvider = context.read<TicketProvider>();
    final storage = context.read<SupabaseStorageDataSource>();

    try {
      final ticket = Ticket(
        id: '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        status: TicketStatus.open,
        priority: _selectedPriority,
        category: _selectedCategory,
        createdBy: auth.currentUser!,
        attachmentUrls: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await ticketProvider.createTicket(ticket);
      if (!mounted) return;

      if (created != null) {
        if (_selectedFiles.isNotEmpty) {
          final urls = await storage.uploadFiles(
            files: _selectedFiles,
            ticketId: created.id,
          );
          await ticketProvider.updateAttachmentUrls(created.id, urls);
        }
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ticketProvider.error ?? 'Gagal membuat tiket'),
            backgroundColor: const Color(0xFF7F1D1D),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengupload file: $e'),
          backgroundColor: const Color(0xFF7F1D1D),
        ),
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Tiket Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Judul', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.textMuted : AppTheme.iconDarkMuted)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              enabled: !_isLoading,
              decoration: const InputDecoration(hintText: 'Judul tiket'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Judul tidak boleh kosong' : null,
            ),
            const SizedBox(height: 20),
            Text('Kategori', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.textMuted : AppTheme.iconDarkMuted)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: _isLoading ? null : (v) => setState(() => _selectedCategory = v ?? 'Hardware'),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined, size: 20)),
            ),
            const SizedBox(height: 20),
            Text('Prioritas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.textMuted : AppTheme.iconDarkMuted)),
            const SizedBox(height: 8),
            SegmentedButton<TicketPriority>(
              segments: TicketPriority.values.map((p) => ButtonSegment(value: p, label: Text(p.label, style: const TextStyle(fontSize: 12)))).toList(),
              selected: {_selectedPriority},
              onSelectionChanged: (v) => setState(() => _selectedPriority = v.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppTheme.accentCyan.withValues(alpha: 0.15),
                selectedForegroundColor: AppTheme.accentCyan,
                side: BorderSide.none,
              ),
            ),
            const SizedBox(height: 20),
            Text('Deskripsi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.textMuted : AppTheme.iconDarkMuted)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              enabled: !_isLoading,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'Deskripsikan masalah Anda...', alignLabelWithHint: true),
              validator: (v) => v == null || v.trim().isEmpty ? 'Deskripsi tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),

            Row(
              spacing: 8,
              children: [
                Icon(Icons.attach_file_rounded, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                Text('Lampiran (${_selectedFiles.length})',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.textMuted : AppTheme.iconDarkMuted)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _isLoading ? null : _showFileSourceSheet,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Tambah', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
            if (_selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedFiles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final file = _selectedFiles[index];
                    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(file.ext);

                    return Stack(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: isImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(file.bytes, fit: BoxFit.cover),
                                )
                              : Center(
                                  child: Icon(
                                    file.ext == 'pdf'
                                        ? Icons.picture_as_pdf_rounded
                                        : Icons.insert_drive_file_rounded,
                                    size: 32,
                                    color: AppTheme.accentCyan.withValues(alpha: 0.6),
                                  ),
                                ),
                        ),
                        Positioned(
                          top: -4, right: -4,
                          child: GestureDetector(
                            onTap: () => _removeFile(index),
                            child: Container(
                              width: 22, height: 22,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDC2626), shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Buat Tiket'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
