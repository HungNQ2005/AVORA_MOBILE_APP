import 'package:equatable/equatable.dart';

class PackingItem extends Equatable {
  final String id;
  final String title;
  final String category; // 'documents', 'clothes', 'electronics', 'toiletries', 'custom'
  final bool isChecked;
  final bool isCustom;

  const PackingItem({
    required this.id,
    required this.title,
    required this.category,
    this.isChecked = false,
    this.isCustom = false,
  });

  PackingItem copyWith({
    String? title,
    String? category,
    bool? isChecked,
    bool? isCustom,
  }) {
    return PackingItem(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      isChecked: isChecked ?? this.isChecked,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'is_checked': isChecked,
      'is_custom': isCustom,
    };
  }

  factory PackingItem.fromJson(Map<String, dynamic> json) {
    return PackingItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      category: (json['category'] ?? 'documents').toString(),
      isChecked: json['is_checked'] == true,
      isCustom: json['is_custom'] == true,
    );
  }

  @override
  List<Object?> get props => [id, title, category, isChecked, isCustom];
}
