import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/service_providers.dart';
import '../core/services/smart_analysis_service.dart';
import '../core/widgets/loading_overlay.dart';
import '../features/auth/presentation/auth_notifier.dart';
import '../models/complaint_type.dart';
import '../models/sector_model.dart';

class ComplaintFormScreen extends ConsumerStatefulWidget {
  const ComplaintFormScreen({super.key});

  @override
  ConsumerState<ComplaintFormScreen> createState() =>
      _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends ConsumerState<ComplaintFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  String _sectorId = CampusSectors.all.first.id;
  ComplaintType _type = ComplaintType.complaint;
  ComplaintPriority _priority = ComplaintPriority.medium;
  bool _isAnonymous = false;
  bool _saving = false;
  SmartAnalysisResult? _analysis;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  void _runAnalysis() {
    if (_title.text.trim().isEmpty && _description.text.trim().isEmpty) return;
    final result = ref.read(smartAnalysisProvider).analyze(
          title: _title.text,
          description: _description.text,
          sectorId: _sectorId,
        );
    setState(() {
      _analysis = result;
      _type = result.suggestedType;
      if (_priority == ComplaintPriority.medium) {
        _priority = result.suggestedPriority;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authStateProvider).user;
    if (auth == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(complaintServiceProvider).submitComplaint(
            studentId: auth.userId,
            title: _title.text,
            description: _description.text,
            sectorId: _sectorId,
            type: _type,
            priority: _priority,
            location: _location.text.trim().isEmpty ? null : _location.text,
            isAnonymous: _isAnonymous,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submitted successfully.')),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
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
      appBar: AppBar(title: const Text('New complaint / suggestion')),
      body: LoadingOverlay(
        loading: _saving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<ComplaintType>(
                  segments: const [
                    ButtonSegment(
                      value: ComplaintType.complaint,
                      label: Text('Complaint'),
                      icon: Icon(Icons.report_problem_outlined),
                    ),
                    ButtonSegment(
                      value: ComplaintType.suggestion,
                      label: Text('Suggestion'),
                      icon: Icon(Icons.lightbulb_outline),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _runAnalysis(),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Short summary of the issue',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _sectorId,
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
                    if (v != null) {
                      setState(() => _sectorId = v);
                      _runAnalysis();
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ComplaintPriority>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: ComplaintPriority.values
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _priority = v);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _location,
                  decoration: const InputDecoration(
                    labelText: 'Location (optional)',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  minLines: 5,
                  maxLines: 12,
                  onChanged: (_) => _runAnalysis(),
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    hintText:
                        'Include dates, locations, and what outcome you expect.',
                  ),
                  validator: (v) => v == null || v.trim().length < 10
                      ? 'Add more detail (min 10 characters)'
                      : null,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Submit anonymously'),
                  subtitle: const Text('Officers see your ticket but not your name'),
                  value: _isAnonymous,
                  onChanged: (v) => setState(() => _isAnonymous = v),
                ),
                if (_analysis != null) ...[
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Smart analysis',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Category: ${_analysis!.suggestedCategory}'),
                          Text('Sentiment: ${_analysis!.sentimentScore.toStringAsFixed(2)}'),
                          if (_analysis!.suggestedTags.isNotEmpty)
                            Text('Tags: ${_analysis!.suggestedTags.join(', ')}'),
                          if (_analysis!.isLikelySpam)
                            Text(
                              'Warning: content may be flagged as low quality.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
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
