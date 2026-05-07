import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/complaint_model.dart';
import '../models/complaint_status.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/sector_model.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/complaint_service.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/status_chip.dart';

class ComplaintDetailScreen extends StatefulWidget {
  const ComplaintDetailScreen({super.key, required this.complaintId});

  final String complaintId;

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final _reply = TextEditingController();
  bool _busy = false;
  String? _studentName;
  String? _lastLoadedStudentId;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _loadStudentName(String studentId) async {
    final u = await context.read<AuthService>().getUserProfile(studentId);
    if (mounted) setState(() => _studentName = u?.name);
  }

  bool _canOfficerAct(AppUser u, Complaint c) {
    return u.role == UserRole.sectorOfficer && u.sectorId == c.sectorId;
  }

  bool _canExecutiveAct(AppUser u, Complaint c) {
    return (u.role == UserRole.vicePresident || u.role == UserRole.president) &&
        c.status == ComplaintStatus.escalated;
  }

  bool _canAdminView(AppUser u) => u.role == UserRole.admin;

  Future<void> _sendReply(Complaint c, AppUser u) async {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    try {
      final exec = _canExecutiveAct(u, c);
      await context.read<ComplaintService>().addResponse(
            complaint: c,
            author: u,
            message: text,
            fromExecutive: exec,
          );
      _reply.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply posted.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setStatus(
    Complaint c,
    AppUser u,
    ComplaintStatus next,
  ) async {
    setState(() => _busy = true);
    try {
      await context.read<ComplaintService>().updateComplaintStatus(
            complaint: c,
            newStatus: next,
            actor: u,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to ${next.displayName}.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>().appUser;
    final svc = context.watch<ComplaintService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Complaint detail')),
      body: LoadingOverlay(
        loading: _busy,
        child: StreamBuilder<Complaint?>(
          stream: svc.streamComplaint(widget.complaintId),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            if (!snap.hasData || snap.data == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            final c = snap.data!;
            if (auth == null) {
              return const Center(child: Text('Not signed in'));
            }
            if (auth.role == UserRole.student && auth.userId != c.studentId) {
              return const Center(
                child: Text('You do not have access to this complaint.'),
              );
            }
            if (c.studentId != _lastLoadedStudentId) {
              _lastLoadedStudentId = c.studentId;
              _studentName = null;
              _loadStudentName(c.studentId);
            }

            final officer = _canOfficerAct(auth, c);
            final executive = _canExecutiveAct(auth, c);
            final canReply = officer || executive;
            final showStatusActions = officer || executive;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              c.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          StatusChip(status: c.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CampusSectors.label(c.sectorId),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Submitted: ${DateFormat.yMMMd().add_jm().format(c.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (_studentName != null || c.studentName != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Student: ${c.studentName ?? _studentName}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        c.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (showStatusActions) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Update status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (officer) ...[
                              FilledButton.tonal(
                                onPressed: c.status == ComplaintStatus.inProgress
                                    ? null
                                    : () => _setStatus(
                                          c,
                                          auth,
                                          ComplaintStatus.inProgress,
                                        ),
                                child: const Text('In progress'),
                              ),
                              FilledButton.tonal(
                                onPressed: c.status == ComplaintStatus.resolved
                                    ? null
                                    : () => _setStatus(
                                          c,
                                          auth,
                                          ComplaintStatus.resolved,
                                        ),
                                child: const Text('Resolved'),
                              ),
                              FilledButton.tonal(
                                onPressed: c.status == ComplaintStatus.escalated
                                    ? null
                                    : () => _setStatus(
                                          c,
                                          auth,
                                          ComplaintStatus.escalated,
                                        ),
                                child: const Text('Escalate'),
                              ),
                            ],
                            if (executive) ...[
                              FilledButton.tonal(
                                onPressed: () => _setStatus(
                                  c,
                                  auth,
                                  ComplaintStatus.inProgress,
                                ),
                                child: const Text('Mark in progress'),
                              ),
                              FilledButton.tonal(
                                onPressed: () => _setStatus(
                                  c,
                                  auth,
                                  ComplaintStatus.resolved,
                                ),
                                child: const Text('Resolve'),
                              ),
                            ],
                          ],
                        ),
                      ],
                      if (_canAdminView(auth)) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Admin view: read-only actions on this screen.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                      const Divider(height: 32),
                      Text(
                        'Thread',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder(
                        stream: svc.streamResponses(c.complaintId),
                        builder: (context, rSnap) {
                          if (!rSnap.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            );
                          }
                          final responses = rSnap.data!;
                          if (responses.isEmpty) {
                            return Text(
                              'No replies yet.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            );
                          }
                          return Column(
                            children: responses.map((r) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(r.message),
                                  subtitle: Text(
                                    DateFormat.yMMMd()
                                        .add_jm()
                                        .format(r.createdAt),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (canReply)
                  Material(
                    elevation: 8,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 12,
                        right: 12,
                        bottom: MediaQuery.paddingOf(context).bottom + 12,
                        top: 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _reply,
                              minLines: 1,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText: 'Write a response…',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => _sendReply(c, auth),
                            child: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
