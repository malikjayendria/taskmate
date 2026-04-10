import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/group_viewmodel.dart';

class GroupListView extends StatelessWidget {
  const GroupListView({super.key});

  @override
  Widget build(BuildContext context) {
    final groupViewModel = context.watch<GroupViewModel>();

    if (groupViewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (groupViewModel.groups.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada kelompok tersedia.\nHubungi admin untuk menambahkanmu.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final group = groupViewModel.groups[index];
          final isSelected = group.id == groupViewModel.selectedGroupId;

          return ChoiceChip(
            label: Text(group.name),
            selected: isSelected,
            onSelected: (_) => groupViewModel.selectGroup(group.id),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: groupViewModel.groups.length,
      ),
    );
  }
}
