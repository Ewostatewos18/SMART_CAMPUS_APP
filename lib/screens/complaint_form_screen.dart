import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sector_model.dart';
import '../providers/auth_provider.dart';
import '../services/complaint_service.dart';
import '../widgets/loading_overlay.dart';

/// Student: submit a new complaint / suggestion.
class ComplaintFormScreen extends StatefulWidget {
  const ComplaintFormScreen({super.key});

  @override
  State<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _sectorId = CampusSectors.all.first.id;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>().appUser;
    if (auth == null) return;
    setState(() => _saving = true);
    try {
      await context.read<ComplaintService>().submitComplaint(
            studentId: auth.userId,
            title: _title.text,
            description: _description.text,
            sectorId: _sectorId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint submitted successfully.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not submit: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New complaint')),
      body: LoadingOverlay(
        loading: _saving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Short summary of the issue',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _sectorId,
                  decoration: const InputDecoration(
                    labelText: 'Sector',
                    hintText: 'Who should handle this?',
                  ),
                  items: CampusSectors.all
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _sectorId = v);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  minLines: 5,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    hintText:
                        'Include dates, locations, and what outcome you expect.',
                  ),
                  validator: (v) =>
                      v == null || v.trim().length < 10 ? 'Add more detail' : null,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
