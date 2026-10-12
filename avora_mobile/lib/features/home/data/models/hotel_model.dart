import 'package:equatable/equatable.dart';

/// Model đại diện cho một khách sạn từ Backend (`GET /api/hotels`).
class HotelModel extends Equatable {
  final String hotelId;
  final String name;
  final String? address;
  final String? cityName;
  final int starQuality;
  final double starRating;
  final String scoreLabel;
  final int reviewsCount;
  final num price;
  final num? originalPrice;
  final String? thumbnail;
  final List<String> images;
  final String? tag;
  final bool isGenius;
  final String hotelStatus;

  const HotelModel({
    required this.hotelId,
    required this.name,
    this.address,
    this.cityName,
    this.starQuality = 5,
    this.starRating = 9.0,
    this.scoreLabel = 'Tuyệt hảo',
    this.reviewsCount = 0,
    required this.price,
    this.originalPrice,
    this.thumbnail,
    this.images = const [],
    this.tag,
    this.isGenius = false,
    this.hotelStatus = 'ACTIVE',
  });

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    List<String> parsedImages = [];
    if (rawImages is List) {
      parsedImages = rawImages.map((e) => e.toString()).toList();
    }

    return HotelModel(
      hotelId: (json['hotel_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? 'Khách sạn chưa đặt tên',
      address: json['address']?.toString(),
      cityName: json['city_name']?.toString(),
      starQuality: (json['star_quality'] as num?)?.toInt() ?? 5,
      starRating: (json['star_rating'] as num?)?.toDouble() ?? 9.0,
      scoreLabel: json['score_label']?.toString() ?? 'Tuyệt hảo',
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?) ?? 0,
      originalPrice: json['original_price'] as num?,
      thumbnail: json['thumbnail']?.toString(),
      images: parsedImages,
      tag: json['tag']?.toString(),
      isGenius: json['is_genius'] == true,
      hotelStatus: json['hotel_status']?.toString() ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() => {
        'hotel_id': hotelId,
        'name': name,
        'address': address,
        'city_name': cityName,
        'star_quality': starQuality,
        'star_rating': starRating,
        'score_label': scoreLabel,
        'reviews_count': reviewsCount,
        'price': price,
        'original_price': originalPrice,
        'thumbnail': thumbnail,
        'images': images,
        'tag': tag,
        'is_genius': isGenius,
        'hotel_status': hotelStatus,
      };

  @override
  List<Object?> get props => [
        hotelId,
        name,
        address,
        cityName,
        starQuality,
        starRating,
        scoreLabel,
        reviewsCount,
        price,
        originalPrice,
        thumbnail,
        images,
        tag,
        isGenius,
        hotelStatus,
      ];
}

/// Model cho điểm đến thịnh hành (Trending Destination).
class TrendingDestination extends Equatable {
  final String name;
  final String subtitle;
  final String imageUrl;
  final String? tag;
  final String? startingPrice;

  const TrendingDestination({
    required this.name,
    required this.subtitle,
    required this.imageUrl,
    this.tag,
    this.startingPrice,
  });

  @override
  List<Object?> get props => [name, subtitle, imageUrl, tag, startingPrice];
}
