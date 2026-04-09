class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String badgeText;
  final String buttonText;
  final String buttonLink;
  final int order;
  final bool isActive;

  BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.badgeText,
    required this.buttonText,
    required this.buttonLink,
    required this.order,
    required this.isActive,
  });

  factory BannerModel.fromFirestore(Map<String, dynamic> data, String id) {
    return BannerModel(
      id: id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      badgeText: data['badgeText'] ?? '',
      buttonText: data['buttonText'] ?? 'Shop Now',
      buttonLink: data['buttonLink'] ?? '',
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
    'badgeText': badgeText,
    'buttonText': buttonText,
    'buttonLink': buttonLink,
    'order': order,
    'isActive': isActive,
  };
}
