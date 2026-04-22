import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/mock_service.dart';
import '../../core/theme/app_theme.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedCategory = 'Hardware';
  final List<String> _categories = ['Hardware', 'Software', 'Network', 'Account'];

  TicketPriority _selectedPriority = TicketPriority.medium;

  bool _hasAttachment = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    // Validasi form agar tidak kosong
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = MockService.currentUser;
      if (user == null) throw Exception('Sesi tidak valid, silakan login ulang.');

      // ID dan History akan dioverride oleh MockService.addTicket
      final newTicket = Ticket(
        id: 0, 
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        status: TicketStatus.open,
        priority: _selectedPriority,
        category: _selectedCategory,
        createdBy: user,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        attachmentUrls: _hasAttachment ? ['dummy_screenshot.png'] : [],
      );

      await MockService.addTicket(newTicket);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiket berhasil dibuat!'),
          backgroundColor: AppTheme.statusResolved,
        ),
      );
      
      // Kembali ke layar List Tiket setelah berhasil
      Navigator.pop(context);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.statusOpen,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Tiket Baru'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Judul Tiket ───────────────────────────────────────────────
              Text(
                'Judul Masalah',
                style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                enabled: !_isLoading,
                decoration: const InputDecoration(hintText: 'Misal: Internet lab komputer B mati'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              // ── Kategori & Prioritas ──────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kategori',
                          style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: _isLoading ? null : (val) => setState(() => _selectedCategory = val!),
                          decoration: const InputDecoration(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prioritas',
                          style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<TicketPriority>(
                          value: _selectedPriority,
                          items: TicketPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(),
                          onChanged: _isLoading ? null : (val) => setState(() => _selectedPriority = val!),
                          decoration: const InputDecoration(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Deskripsi ─────────────────────────────────────────────────
              Text(
                'Deskripsi Lengkap',
                style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                enabled: !_isLoading,
                maxLines: 5,
                decoration: const InputDecoration(hintText: 'Jelaskan kronologi dan detail masalah yang dialami...'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              // ── Mock Upload Lampiran ──────────────────────────────────────
              Text(
                'Lampiran (Opsional)',
                style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : () => setState(() => _hasAttachment = !_hasAttachment),
                icon: Icon(
                  _hasAttachment ? Icons.check_circle_rounded : Icons.attach_file_rounded, 
                  color: _hasAttachment ? AppTheme.statusResolved : theme.colorScheme.onSurface.withOpacity(0.6)
                ),
                label: Text(
                  _hasAttachment ? '1 file siap diunggah (dummy_screenshot.png)' : 'Pilih Lampiran',
                  style: TextStyle(color: _hasAttachment ? AppTheme.statusResolved : null),
                ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 40),

              // ── Tombol Submit ─────────────────────────────────────────────
              ElevatedButton(
                onPressed: _isLoading ? null : _submitTicket,
                child: _isLoading
                    ? const SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                      )
                    : const Text('Kirim Tiket'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}