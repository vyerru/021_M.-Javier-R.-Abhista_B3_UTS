import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/entities.dart';
import '../../core/theme/app_theme.dart';
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final ticketProvider = context.read<TicketProvider>();

    final ticket = Ticket(
      id: '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      status: TicketStatus.open,
      priority: _selectedPriority,
      category: _selectedCategory,
      createdBy: auth.currentUser!,
      attachmentUrls: _hasAttachment ? ['mock_attachment.pdf'] : [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ticketProvider.createTicket(ticket);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ticketProvider.error ?? 'Gagal membuat tiket'), backgroundColor: const Color(0xFF7F1D1D)),
      );
    }
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
            Text('Judul', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              enabled: !_isLoading,
              decoration: const InputDecoration(hintText: 'Judul tiket'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Judul tidak boleh kosong' : null,
            ),
            const SizedBox(height: 20),
            Text('Kategori', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: _isLoading ? null : (v) => setState(() => _selectedCategory = v ?? 'Hardware'),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined, size: 20)),
            ),
            const SizedBox(height: 20),
            Text('Prioritas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
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
            Text('Deskripsi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              enabled: !_isLoading,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'Deskripsikan masalah Anda...', alignLabelWithHint: true),
              validator: (v) => v == null || v.trim().isEmpty ? 'Deskripsi tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Lampirkan File', style: TextStyle(fontSize: 14)),
              subtitle: const Text('mock_attachment.pdf', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              value: _hasAttachment,
              onChanged: !_isLoading ? (v) => setState(() => _hasAttachment = v) : null,
              contentPadding: EdgeInsets.zero,
              activeColor: AppTheme.accentCyan,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Buat Tiket'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
