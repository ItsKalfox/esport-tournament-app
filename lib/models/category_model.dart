class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? color;
  final int order;
  final bool isActive;

  // Icon — matches what admin panel saves
  // icon field in Firestore: { type: 'library', id: 'cpu' } or { type: 'url', value: 'https://...' }
  final String? iconType; // 'library' or 'url'
  final String? iconId; // used when type = 'library'
  final String? iconValue; // used when type = 'url'

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.color,
    required this.order,
    required this.isActive,
    this.iconType,
    this.iconId,
    this.iconValue,
  });

  factory CategoryModel.fromFirestore(Map<String, dynamic> data, String id) {
    final icon = data['icon'];
    String? iconType, iconId, iconValue;

    if (icon is Map) {
      iconType = icon['type']?.toString();
      if (iconType == 'library') {
        iconId = icon['id']?.toString();
      } else if (iconType == 'url') {
        iconValue = icon['value']?.toString();
      }
    }

    return CategoryModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'],
      color: data['color'],
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      iconType: iconType,
      iconId: iconId,
      iconValue: iconValue,
    );
  }
}
