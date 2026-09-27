import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/generated/app_localizations.dart';
import 'plant_controller.dart';
import 'plant_store.dart';

const _leaf = Color(0xff80d7a6);
const _soil = Color(0xff2b3c37);

List<HomePlant> _sortedPlants(List<HomePlant> plants) =>
    [...plants]..sort((a, b) {
      final due = a.nextWateringAt.compareTo(b.nextWateringAt);
      return due != 0 ? due : a.name.compareTo(b.name);
    });

String _dueLabel(AppLocalizations l10n, HomePlant plant, DateTime now) {
  final days = plant.daysUntilWatering(now);
  if (days < 0) return l10n.plantsOverdue(-days);
  if (days == 0) return l10n.plantsDueToday;
  return l10n.plantsDueIn(days);
}

class PlantsHomeSection extends StatelessWidget {
  const PlantsHomeSection({required this.controller, super.key});

  final PlantController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      final plants = _sortedPlants(controller.plants);
      final due = plants
          .where((plant) => plant.daysUntilWatering(DateTime.now()) <= 0)
          .length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? _soil
                  : const Color(0xffdcece1),
              borderRadius: BorderRadius.circular(29),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.spa_rounded, color: _leaf, size: 30),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _openPlants(context, controller),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(l10n.plantsSeeAll),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.plantsTitle,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: Text(
                    controller.error != null
                        ? l10n.plantsLoadError
                        : plants.isEmpty
                        ? l10n.plantsEmpty
                        : due == 0
                        ? l10n.plantsAllGood
                        : l10n.plantsDueCount(due),
                    key: ValueKey('${plants.length}:$due:${controller.error}'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (plants.isEmpty) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () =>
                        _openPlants(context, controller, add: true),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.plantsAdd),
                  ),
                ],
              ],
            ),
          ),
          if (plants.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 174,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: plants.length.clamp(0, 4),
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) => SizedBox(
                  width: 174,
                  child: _PlantTile(
                    plant: plants[index],
                    controller: controller,
                    onTap: () => _openPlants(context, controller),
                    compact: true,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}

class PlantsPlanSection extends StatelessWidget {
  const PlantsPlanSection({required this.controller, super.key});

  final PlantController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final plants = _sortedPlants(controller.plants);
      if (plants.isEmpty) return const SizedBox.shrink();
      final l10n = AppLocalizations.of(context);
      return Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.plantsTitle,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: () => _openPlants(context, controller),
                  child: Text(l10n.plantsSeeAll),
                ),
              ],
            ),
            ...plants
                .take(3)
                .map(
                  (plant) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.water_drop_rounded, color: _leaf),
                    title: Text(plant.name),
                    subtitle: Text(_dueLabel(l10n, plant, DateTime.now())),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _openPlants(context, controller),
                  ),
                ),
          ],
        ),
      );
    },
  );
}

void _openPlants(
  BuildContext context,
  PlantController controller, {
  bool add = false,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PlantsPage(controller: controller, addOnOpen: add),
    ),
  );
}

class PlantsPage extends StatefulWidget {
  const PlantsPage({
    required this.controller,
    this.addOnOpen = false,
    super.key,
  });
  final PlantController controller;
  final bool addOnOpen;

  @override
  State<PlantsPage> createState() => _PlantsPageState();
}

class _PlantsPageState extends State<PlantsPage> {
  @override
  void initState() {
    super.initState();
    if (widget.addOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _editPlant(context, widget.controller);
      });
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      final plants = _sortedPlants(widget.controller.plants);
      final now = DateTime.now();
      final due = plants
          .where((item) => item.daysUntilWatering(now) <= 0)
          .length;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.plantsTitle)),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _editPlant(context, widget.controller),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.plantsAdd),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 110),
            children: [
              Text(
                l10n.plantsSubtitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 18),
              _Summary(pCount: plants.length, dueCount: due),
              const SizedBox(height: 20),
              if (widget.controller.error != null)
                Text(l10n.plantsLoadError)
              else if (plants.isEmpty)
                _EmptyGarden(
                  onAdd: () => _editPlant(context, widget.controller),
                )
              else
                ...plants.map(
                  (plant) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PlantTile(
                      plant: plant,
                      controller: widget.controller,
                      onTap: () =>
                          _showPlant(context, widget.controller, plant),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Text(
                l10n.plantsLocalOnly,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.pCount, required this.dueCount});
  final int pCount;
  final int dueCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? _soil
            : const Color(0xffdcece1),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          const Icon(Icons.spa_rounded, color: _leaf, size: 42),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$pCount',
                  style: Theme.of(context).textTheme.headlineLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  dueCount == 0
                      ? l10n.plantsAllGood
                      : l10n.plantsDueCount(dueCount),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGarden extends StatelessWidget {
  const _EmptyGarden({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          Icon(
            Icons.yard_rounded,
            size: 76,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .55),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.plantsEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: onAdd, child: Text(l10n.plantsAdd)),
        ],
      ),
    );
  }
}

class _PlantTile extends StatelessWidget {
  const _PlantTile({
    required this.plant,
    required this.controller,
    required this.onTap,
    this.compact = false,
  });
  final HomePlant plant;
  final PlantController controller;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final days = plant.daysUntilWatering(DateTime.now());
    final dueColor = days <= 0 ? const Color(0xffeb9d6b) : _leaf;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? const Color(0xff202a2b) : const Color(0xfff0f5f0),
      borderRadius: BorderRadius.circular(25),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: compact
            ? Stack(
                fit: StackFit.expand,
                children: [
                  _PlantPhoto(plant: plant, controller: controller),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 66,
                    child: ColoredBox(color: Color(0xd915251d)),
                  ),
                  Positioned(
                    left: 13,
                    right: 13,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          _dueLabel(l10n, plant, DateTime.now()),
                          style: TextStyle(
                            color: dueColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 205,
                    child: _PlantPhoto(plant: plant, controller: controller),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                plant.name,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                        if (plant.species.isNotEmpty ||
                            plant.location.isNotEmpty)
                          Text(
                            [
                              plant.species,
                              plant.location,
                            ].where((item) => item.isNotEmpty).join(' · '),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.water_drop_rounded,
                              size: 18,
                              color: dueColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _dueLabel(l10n, plant, DateTime.now()),
                              style: TextStyle(
                                color: dueColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              plant.intervalDays == 1
                                  ? l10n.plantsEveryDay
                                  : l10n.plantsEveryDays(plant.intervalDays),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PlantPhoto extends StatefulWidget {
  const _PlantPhoto({required this.plant, required this.controller});
  final HomePlant plant;
  final PlantController controller;

  @override
  State<_PlantPhoto> createState() => _PlantPhotoState();
}

class _PlantPhotoState extends State<_PlantPhoto> {
  late Future<File?> _photo;

  @override
  void initState() {
    super.initState();
    _photo = widget.controller.store.photoFile(widget.plant.photoName);
  }

  @override
  void didUpdateWidget(covariant _PlantPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plant.photoName != widget.plant.photoName ||
        oldWidget.controller != widget.controller) {
      _photo = widget.controller.store.photoFile(widget.plant.photoName);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<File?>(
    future: _photo,
    builder: (context, snapshot) {
      final file = snapshot.data;
      if (file != null) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final logicalWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : 600.0;
            final pixels =
                (logicalWidth * MediaQuery.devicePixelRatioOf(context))
                    .ceil()
                    .clamp(1, 1600);
            return Image.file(
              file,
              fit: BoxFit.cover,
              cacheWidth: pixels,
              errorBuilder: (_, _, _) => _placeholder(context),
            );
          },
        );
      }
      return _placeholder(context);
    },
  );

  Widget _placeholder(BuildContext context) => Container(
    decoration: const BoxDecoration(color: Color(0xff354e3e)),
    child: const Center(
      child: Icon(Icons.spa_rounded, color: Color(0xffa6dcaa), size: 70),
    ),
  );
}

Future<void> _showPlant(
  BuildContext context,
  PlantController controller,
  HomePlant plant,
) async {
  final l10n = AppLocalizations.of(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              plant.name,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (plant.species.isNotEmpty) Text(plant.species),
            const SizedBox(height: 18),
            Text(
              _dueLabel(l10n, plant, DateTime.now()),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              plant.intervalDays == 1
                  ? l10n.plantsEveryDay
                  : l10n.plantsEveryDays(plant.intervalDays),
            ),
            if (plant.notes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(plant.notes),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () async {
                await controller.water(plant, DateTime.now());
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.plantsWatered),
                      action: SnackBarAction(
                        label: l10n.plantsUndo,
                        onPressed: () =>
                            controller.water(plant, plant.lastWateredAt),
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.water_drop_rounded),
              label: Text(l10n.plantsWaterNow),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                _editPlant(context, controller, plant);
              },
              icon: const Icon(Icons.edit_rounded),
              label: Text(l10n.plantsEdit),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _editPlant(
  BuildContext context,
  PlantController controller, [
  HomePlant? original,
]) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) =>
        _PlantEditor(controller: controller, original: original),
  );
}

class _PlantEditor extends StatefulWidget {
  const _PlantEditor({required this.controller, this.original});
  final PlantController controller;
  final HomePlant? original;

  @override
  State<_PlantEditor> createState() => _PlantEditorState();
}

class _PlantEditorState extends State<_PlantEditor> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.original?.name ?? '');
  late final species = TextEditingController(
    text: widget.original?.species ?? '',
  );
  late final room = TextEditingController(
    text: widget.original?.location ?? '',
  );
  late final notes = TextEditingController(text: widget.original?.notes ?? '');
  late int interval = widget.original?.intervalDays ?? 7;
  late DateTime lastWatered = widget.original?.lastWateredAt ?? DateTime.now();
  XFile? pickedPhoto;
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    species.dispose();
    room.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
      );
      if (picked != null && mounted) setState(() => pickedPhoto = picked);
    } on Object {
      if (mounted) _message(AppLocalizations.of(context).plantsPhotoError);
    }
  }

  void _message(String value) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));

  Future<void> _save() async {
    if (!form.currentState!.validate() || saving) return;
    setState(() => saving = true);
    String? newPhoto;
    try {
      if (pickedPhoto != null) {
        newPhoto = await widget.controller.savePhoto(pickedPhoto!);
      }
      final current = widget.original;
      final plant = HomePlant(
        id: current?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: name.text.trim(),
        species: species.text.trim(),
        location: room.text.trim(),
        notes: notes.text.trim(),
        intervalDays: interval,
        lastWateredAt: lastWatered,
        createdAt: current?.createdAt ?? DateTime.now(),
        photoName: newPhoto ?? current?.photoName,
      );
      await widget.controller.save(plant);
      if (newPhoto != null) {
        try {
          await widget.controller.removePhoto(current?.photoName);
        } on Object {
          // Saving the plant must not fail when old photo cleanup fails.
        }
      }
      if (mounted) Navigator.pop(context);
    } on Object {
      if (newPhoto != null) await widget.controller.removePhoto(newPhoto);
      if (mounted) {
        setState(() => saving = false);
        _message(AppLocalizations.of(context).plantsSaveError);
      }
    }
  }

  Future<void> _delete() async {
    final original = widget.original;
    if (original == null) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.plantsDelete),
        content: Text(l10n.plantsDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.plantsDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.controller.delete(original);
      if (mounted) Navigator.pop(context);
    } on Object {
      if (mounted) _message(l10n.plantsSaveError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .83,
          ),
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
              children: [
                Text(
                  widget.original == null ? l10n.plantsAdd : l10n.plantsEdit,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 145,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: pickedPhoto != null
                        ? Image.file(File(pickedPhoto!.path), fit: BoxFit.cover)
                        : _PlantPhoto(
                            plant:
                                widget.original ??
                                HomePlant(
                                  id: '',
                                  name: '',
                                  species: '',
                                  location: '',
                                  intervalDays: 7,
                                  lastWateredAt: DateTime.now(),
                                  createdAt: DateTime.now(),
                                ),
                            controller: widget.controller,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded),
                        label: Text(l10n.plantsGallery),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _pick(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: Text(l10n.plantsCamera),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: name,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: l10n.plantsName),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.plantsName
                      : null,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: species,
                  maxLength: 80,
                  decoration: InputDecoration(labelText: l10n.plantsSpecies),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: room,
                  maxLength: 80,
                  decoration: InputDecoration(labelText: l10n.plantsRoom),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.plantsInterval,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: interval > 1
                          ? () => setState(() => interval--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                    Expanded(
                      child: Slider(
                        value: interval.toDouble(),
                        min: 1,
                        max: 90,
                        divisions: 89,
                        label: '$interval',
                        onChanged: (value) =>
                            setState(() => interval = value.round()),
                      ),
                    ),
                    IconButton(
                      onPressed: interval < 90
                          ? () => setState(() => interval++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                  ],
                ),
                Text(
                  interval == 1
                      ? l10n.plantsEveryDay
                      : l10n.plantsEveryDays(interval),
                ),
                const SizedBox(height: 15),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_rounded),
                  title: Text(l10n.plantsLastWatered),
                  subtitle: Text(
                    MaterialLocalizations.of(context)
                        .formatMediumDate(lastWatered),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: lastWatered,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => lastWatered = date);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notes,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: l10n.plantsNotes),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: saving ? null : _save,
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.plantsSave),
                ),
                if (widget.original != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: saving ? null : _delete,
                    child: Text(l10n.plantsDelete),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
