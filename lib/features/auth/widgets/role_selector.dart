import 'package:flutter/material.dart';

import '../../../models/user_role.dart';

class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Register as',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final useDropdown = constraints.maxWidth < 400;
            if (useDropdown) {
              return DropdownButtonFormField<UserRole>(
                value: value,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: UserRole.values
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(r.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (r) {
                  if (r != null) onChanged(r);
                },
              );
            }
            return SegmentedButton<UserRole>(
              segments: UserRole.values
                  .map(
                    (r) => ButtonSegment(
                      value: r,
                      label: Text(
                        r.displayName,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  )
                  .toList(),
              selected: {value},
              onSelectionChanged: (s) => onChanged(s.first),
            );
          },
        ),
      ],
    );
  }
}
