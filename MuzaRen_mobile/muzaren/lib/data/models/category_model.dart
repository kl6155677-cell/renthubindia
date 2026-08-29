import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String? icon;
  final String slug;

  const CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    required this.slug,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String?,
      slug: json['slug'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'slug': slug,
    };
  }

  @override
  List<Object?> get props => [id, name, icon, slug];
}
