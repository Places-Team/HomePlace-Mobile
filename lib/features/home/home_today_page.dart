import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../link/mobile_models.dart';
import '../connection/connection_controller.dart';
import '../plants/plant_controller.dart';
import '../plants/plant_store.dart';
import '../plants/plants_view.dart';
import 'home_controller.dart';

class HomeTodayPage extends StatelessWidget {
  const HomeTodayPage({
    required this.overview,
    required this.home,
    required this.connection,
    required this.plants,
    required this.onOpenPlan,
    super.key,
  });

  final MobileOverview overview;
  final HomeController home;
  final ConnectionController connection;
  final PlantController? plants;
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    final controller = plants;
    if (controller == null) return _content(context, const []);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _content(context, controller.plants),
    );
  }

  Widget _content(BuildContext context, List<HomePlant> allPlants) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final ordered = [...allPlants]
      ..sort((a, b) => a.nextWateringAt.compareTo(b.nextWateringAt));
    final due = ordered
        .where((plant) => plant.daysUntilWatering(now) <= 0)
        .take(3)
        .toList(growable: false);
    final next = _nextAction(overview, now);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: home.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 3,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          MaterialLocalizations.of(context)
                              .formatMediumDate(now),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (due.isEmpty) ...[
                    _NextActionSection(next: next, onOpenPlan: onOpenPlan),
                    const SizedBox(height: 16),
                  ],
                  if (due.isNotEmpty && plants != null) ...[
                    _DuePlantFeature(
                      plant: due.first,
                      controller: plants!,
                      dueCount: ordered
                          .where((plant) => plant.daysUntilWatering(now) <= 0)
                          .length,
                    ),
                    const SizedBox(height: 22),
                    _SectionTitle(
                      title: l10n.needsWatering,
                      action: l10n.plantsSeeAll,
                      onAction: () => _openPlants(context),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 174,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: due.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) => SizedBox(
                          width: 168,
                          child: _DuePlantTile(
                            plant: due[index],
                            controller: plants!,
                            onTap: () => _openPlants(
                              context,
                              initialPlantId: due[index].id,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else if (ordered.isNotEmpty && plants != null)
                    _CompactPlantPreview(
                      plant: ordered.first,
                      onTap: () => _openPlants(
                        context,
                        initialPlantId: ordered.first.id,
                      ),
                    )
                  else if (plants != null)
                    _EmptyPlantPreview(
                      onAdd: () => _openPlants(context, add: true),
                    ),
                  if (!overview.permissions.contains('dashboard.read')) ...[
                    const SizedBox(height: 14),
                    Text(
                      l10n.permissionsRequired,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  if (due.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _NextActionSection(next: next, onOpenPlan: onOpenPlan),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPlants(
    BuildContext context, {
    bool add = false,
    String? initialPlantId,
  }) {
    final controller = plants;
    if (controller == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PlantsPage(
          controller: controller,
          addOnOpen: add,
          initialPlantId: initialPlantId,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.action,
    required this.onAction,
  });
  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      TextButton.icon(
        onPressed: onAction,
        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
        label: Text(action),
      ),
    ],
  );
}

class _NextActionSection extends StatelessWidget {
  const _NextActionSection({required this.next, required this.onOpenPlan});
  final (String, DateTime, bool)? next;
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: l10n.nextUp,
          action: l10n.calendarTab,
          onAction: onOpenPlan,
        ),
        const SizedBox(height: 10),
        Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onOpenPlan,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 66,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xfff0a58c)
                          : const Color(0xffe78d77),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(18),
                      ),
                    ),
                    child: next == null
                        ? const Icon(Icons.home_outlined)
                        : Text(
                            '${next!.$2.toLocal().day}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: const Color(0xff1d2922),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          next?.$1 ?? l10n.nothingPlanned,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        if (next != null)
                          Text(
                            _when(context, next!.$2, next!.$3),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DuePlantFeature extends StatelessWidget {
  const _DuePlantFeature({
    required this.plant,
    required this.controller,
    required this.dueCount,
  });
  final HomePlant plant;
  final PlantController controller;
  final int dueCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stack = MediaQuery.textScalerOf(context).scale(1) > 1.25;
    final image = SizedBox(
      width: stack ? double.infinity : 128,
      height: stack ? 118 : 204,
      child: PlantPhoto(plant: plant, controller: controller),
    );
    final details = Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.spa_rounded, color: theme.colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            l10n.plantsDueCount(dueCount),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: 'Literata',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => PlantsPage(controller: controller),
              ),
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(l10n.carePlants),
          ),
        ],
      ),
    );
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(12),
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(28),
      ),
      child: ColoredBox(
        color: theme.brightness == Brightness.dark
            ? const Color(0xff21382b)
            : const Color(0xffdce9d7),
        child: stack
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [image, details],
              )
            : Row(
                children: [
                  image,
                  Expanded(child: details),
                ],
              ),
      ),
    );
  }
}

class _DuePlantTile extends StatelessWidget {
  const _DuePlantTile({
    required this.plant,
    required this.controller,
    required this.onTap,
  });
  final HomePlant plant;
  final PlantController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.primary,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: PlantPhoto(plant: plant, controller: controller),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  AppLocalizations.of(context).plantsDueToday,
                  style: const TextStyle(color: Color(0xfff0a58c)),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CompactPlantPreview extends StatelessWidget {
  const _CompactPlantPreview({required this.plant, required this.onTap});
  final HomePlant plant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
    leading: const Icon(Icons.spa_rounded),
    title: Text(AppLocalizations.of(context).nextWatering),
    subtitle: Text(plant.name, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: Text(
      MaterialLocalizations.of(context).formatMediumDate(plant.nextWateringAt),
    ),
    onTap: onTap,
  );
}

class _EmptyPlantPreview extends StatelessWidget {
  const _EmptyPlantPreview({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).plantsEmpty),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: Text(AppLocalizations.of(context).plantsAdd),
        ),
      ],
    ),
  );
}

(String, DateTime, bool)? _nextAction(MobileOverview overview, DateTime now) {
  final candidates = <(String, DateTime, bool)>[
    ...overview.reminders
        .where((item) => !item.done && !item.at.isBefore(now))
        .map((item) => (item.title, item.at, false)),
    ...overview.calendar.events
        .where((item) => item.end.isAfter(now))
        .map((item) => (item.summary, item.start, item.allDay)),
  ]..sort((a, b) => a.$2.compareTo(b.$2));
  return candidates.firstOrNull;
}

String _when(BuildContext context, DateTime raw, bool allDay) {
  final date = raw.toLocal();
  final l10n = AppLocalizations.of(context);
  final today = DateUtils.dateOnly(DateTime.now());
  final day = DateUtils.dateOnly(date);
  final label = day == today
      ? l10n.today
      : day == today.add(const Duration(days: 1))
      ? l10n.tomorrow
      : MaterialLocalizations.of(context).formatMediumDate(date);
  return allDay
      ? '$label · ${l10n.allDay}'
      : '$label · ${TimeOfDay.fromDateTime(date).format(context)}';
}
