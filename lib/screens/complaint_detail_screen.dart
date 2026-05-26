import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/providers/service_providers.dart';
import '../core/widgets/loading_overlay.dart';
import '../core/widgets/status_chip.dart';
import '../features/auth/presentation/auth_notifier.dart';
import '../models/complaint_model.dart';
import '../models/complaint_status.dart';
import '../models/complaint_type.dart';
import '../models/sector_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class ComplaintDetailScreen extends ConsumerStatefulWidget {
  const ComplaintDetailScreen({super.key, required this.complaintId});

  final String complaintId;

  @override
  ConsumerState<ComplaintDetailScreen> createState() =>
      _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends ConsumerState<ComplaintDetailScreen> {
  final _reply = TextEditingController();
  bool _busy = false;
  String? _studentName;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _loadStudentName(String studentId) async {
    final u = await ref.read(authServiceProvider).getUserProfile(studentId);
    if (mounted) setState(() => _studentName = u?.name);
  }

  bool _canOfficerAct(AppUser u, Complaint c) =>
      u.role == UserRole.sectorOfficer && u.sectorId == c.sectorId;

  bool _canExecutiveAct(AppUser u, Complaint c) =>
      (u.role == UserRole.vicePresident || u.role == UserRole.president) &&
      c.status == ComplaintStatus.escalated;

  bool _canStudentAct(AppUser u, Complaint c) =>
      u.role == UserRole.student && u.userId == c.studentId;

  Future<void> _sendReply(Complaint c, AppUser u) async {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(complaintServiceProvider).addResponse(
            complaint: c,
            author: u,
            message: text,
            fromExecutive: _canExecutiveAct(u, c),
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

  Future<void> _setStatus(Complaint c, AppUser u, ComplaintStatus next) async {
    setState(() => _busy = true);
    try {
      await ref.read(complaintServiceProvider).updateComplaintStatus(
            complaint: c,
            newStatus: next,
            actor: u,
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rate(Complaint c, SatisfactionRating rating) async {
    await ref.read(complaintServiceProvider).rateSatisfaction(
          complaint: c,
          rating: rating,
        );
  }

  Future<void> _reopen(Complaint c) async {
    await ref.read(complaintServiceProvider).reopenComplaint(
          complaint: c,
          reason: 'Student requested reopen',
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider).appUser;
    final svc = ref.watch(complaintServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ticket detail')),
      body: LoadingOverlay(
        loading: _busy,
        child: StreamBuilder<Complaint?>(
          stream: svc.streamComplaint(widget.complaintId),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            if (!snap.hasData || snap.data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final c = snap.data!;
            if (auth == null) {
              return const Center(child: Text('Not signed in'));
            }
            if (auth.role == UserRole.student && auth.userId != c.studentId) {
              return const Center(child: Text('Access denied.'));
            }

            if (!c.isAnonymous && _studentName == null) {
              _loadStudentName(c.studentId);
            }

            final officer = _canOfficerAct(auth, c);
            final executive = _canExecutiveAct(auth, c);
            final student = _canStudentAct(auth, c);
            final canReply = officer || executive || student;

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
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          TypeChip(type: c.type),
                          PriorityChip(priority: c.priority),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.domain,
                        label: CampusSectors.label(c.sectorId),
                      ),
                      _InfoRow(
                        icon: Icons.schedule,
                        label: DateFormat.yMMMd().add_jm().format(c.createdAt),
                      ),
                      if (c.location != null && c.location!.isNotEmpty)
                        _InfoRow(icon: Icons.place, label: c.location!),
                      if (!c.isAnonymous && (_studentName != null || c.studentName != null))
                        _InfoRow(
                          icon: Icons.person,
                          label: c.studentName ?? _studentName ?? '',
                        ),
                      if (c.isAnonymous)
                        const _InfoRow(icon: Icons.visibility_off, label: 'Anonymous submission'),
                      if (c.category != null)
                        _InfoRow(icon: Icons.category, label: c.category!),
                      const SizedBox(height: 16),
                      Text(c.description),
                      if (c.tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          children: c.tags
                              .map((t) => Chip(label: Text(t), visualDensity: VisualDensity.compact))
                              .toList(),
                        ),
                      ],
                      if (officer || executive) ...[
                        const SizedBox(height: 24),
                        Text('Update status',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (officer) ...[
                              _StatusButton(
                                label: 'Assign',
                                enabled: c.status == ComplaintStatus.submitted,
                                onTap: () => _setStatus(c, auth, ComplaintStatus.assigned),
                              ),
                              _StatusButton(
                                label: 'In review',
                                enabled: !c.status.isTerminal,
                                onTap: () => _setStatus(c, auth, ComplaintStatus.inReview),
                              ),
                              _StatusButton(
                                label: 'In progress',
                                enabled: !c.status.isTerminal,
                                onTap: () => _setStatus(c, auth, ComplaintStatus.inProgress),
                              ),
                              _StatusButton(
                                label: 'Resolved',
                                enabled: c.status != ComplaintStatus.resolved,
                                onTap: () => _setStatus(c, auth, ComplaintStatus.resolved),
                              ),
                              _StatusButton(
                                label: 'Escalate',
                                enabled: c.status != ComplaintStatus.escalated,
                                onTap: () => _setStatus(c, auth, ComplaintStatus.escalated),
                              ),
                            ],
                            if (executive) ...[
                              _StatusButton(
                                label: 'In progress',
                                onTap: () => _setStatus(c, auth, ComplaintStatus.inProgress),
                              ),
                              _StatusButton(
                                label: 'Resolve',
                                onTap: () => _setStatus(c, auth, ComplaintStatus.resolved),
                              ),
                              _StatusButton(
                                label: 'Close',
                                onTap: () => _setStatus(c, auth, ComplaintStatus.closed),
                              ),
                            ],
                          ],
                        ),
                      ],
                      if (student && c.status == ComplaintStatus.resolved) ...[
                        const SizedBox(height: 20),
                        Text('Were you satisfied?',
                            style: Theme.of(context).textTheme.titleMedium),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _rate(c, SatisfactionRating.satisfied),
                                icon: const Icon(Icons.thumb_up_outlined),
                                label: const Text('Yes'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _rate(c, SatisfactionRating.unsatisfied),
                                icon: const Icon(Icons.thumb_down_outlined),
                                label: const Text('No'),
                              ),
                            ),
                          ],
                        ),
                        if (c.satisfaction == SatisfactionRating.unsatisfied)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton(
                              onPressed: () => _reopen(c),
                              child: const Text('Reopen complaint'),
                            ),
                          ),
                      ],
                      const Divider(height: 32),
                      Text('Discussion thread',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      StreamBuilder(
                        stream: svc.streamResponses(c.complaintId),
                        builder: (context, rSnap) {
                          if (!rSnap.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final responses = rSnap.data!;
                          if (responses.isEmpty) {
                            return Text(
                              'No messages yet. Start the conversation below.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            );
                          }
                          return Column(
                            children: responses.map((r) {
                              return Align(
                                alignment: r.officerId == auth.userId
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.displayAuthor,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(r.message),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat.jm().format(r.createdAt),
                                        style: Theme.of(context).textTheme.labelSmall,
                                      ),
                                    ],
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
                                hintText: 'Write a message…',
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: enabled ? onTap : null,
      child: Text(label),
    );
  }
}
