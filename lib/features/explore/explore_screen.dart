import 'package:adondeamos/app/app_theme.dart';
import 'package:adondeamos/core/animations/animated_list_item.dart';
import 'package:adondeamos/core/animations/press_feedback.dart';
import 'package:adondeamos/shared/widgets/photo_card.dart';
import 'package:adondeamos/shared/widgets/sample_data.dart';
import 'package:adondeamos/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar'),
        actions: [
          PressFeedback(
            onTap: () {},
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          AnimatedListItem(
            index: 0,
            child: Row(
              children: [
                const Icon(Icons.place_outlined, color: AppTheme.violet, size: 18),
                const SizedBox(width: 6),
                const Text(
                  'Cerca de mí',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text('Ver todo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          AnimatedListItem(
            index: 1,
            child: SizedBox(
              height: 176,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final place = samplePlaces[index + 1];
                  return SizedBox(
                    width: 138,
                    child: PressFeedback(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {},
                      child: PhotoCard(
                        title: place.name,
                        subtitle: '${place.category} · ${place.distance}',
                        imageUrl: place.imageUrl,
                        badge: '${place.match}%',
                        height: 176,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedListItem(
            index: 2,
            child: const SectionHeader(title: 'Populares esta semana', action: 'Ver todo'),
          ),
          AnimatedListItem(
            index: 3,
            child: PressFeedback(
              borderRadius: BorderRadius.circular(22),
              onTap: () {},
              child: PhotoCard(
                title: 'Siembra Comedor',
                subtitle: 'Vegetariana · 2.3 km · 4.5',
                imageUrl:
                    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=900&q=80',
                height: 210,
              ),
            ),
          ),
          const SizedBox(height: 18),
          AnimatedListItem(
            index: 4,
            child: const SectionHeader(title: 'Categorías locales'),
          ),
          AnimatedListItem(
            index: 5,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _ExploreChip(icon: Icons.restaurant_rounded, label: 'Taquerías'),
                _ExploreChip(icon: Icons.local_bar_rounded, label: 'Bares'),
                _ExploreChip(icon: Icons.icecream_rounded, label: 'Postres'),
                _ExploreChip(icon: Icons.park_rounded, label: 'Al aire libre'),
                _ExploreChip(icon: Icons.family_restroom_rounded, label: 'Familia'),
                _ExploreChip(icon: Icons.favorite_rounded, label: 'Citas'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreChip extends StatelessWidget {
  const _ExploreChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PressFeedback(
      borderRadius: BorderRadius.circular(18),
      onTap: () {},
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppTheme.violet, size: 18),
              const SizedBox(width: 7),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
