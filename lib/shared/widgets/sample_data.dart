class SamplePlace {
  const SamplePlace({
    required this.name,
    required this.category,
    required this.location,
    required this.distance,
    required this.imageUrl,
    this.match = 91,
  });

  final String name;
  final String category;
  final String location;
  final String distance;
  final String imageUrl;
  final int match;
}

const samplePlaces = [
  SamplePlace(
    name: 'Terraza Lúcida',
    category: 'Italiana',
    location: 'Nuevo Laredo',
    distance: '5.2 km',
    match: 95,
    imageUrl:
        'https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&w=900&q=80',
  ),
  SamplePlace(
    name: 'Café Ocampo',
    category: 'Cafetería',
    location: 'Centro',
    distance: '1.8 km',
    match: 90,
    imageUrl:
        'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=900&q=80',
  ),
  SamplePlace(
    name: 'Cantina El Bajío',
    category: 'Mexicana',
    location: 'Colonia Jardín',
    distance: '2.4 km',
    match: 88,
    imageUrl:
        'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&fit=crop&w=900&q=80',
  ),
  SamplePlace(
    name: 'Burger House',
    category: 'Hamburguesas',
    location: 'Madero',
    distance: '2.1 km',
    match: 82,
    imageUrl:
        'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=900&q=80',
  ),
];
