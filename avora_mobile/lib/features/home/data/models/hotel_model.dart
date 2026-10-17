import 'package:equatable/equatable.dart';

/// Model đại diện cho một khách sạn từ Backend (`GET /api/hotels`).
class HotelModel extends Equatable {
  final String hotelId;
  final String name;
  final String? description;
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
  final double? lat;
  final double? lng;
  final int? availableRooms;
  final List<HotelFacility> facilities;
  final RoomHighlight? roomHighlight;
  final CancellationPolicy? cancellationPolicy;

  const HotelModel({
    required this.hotelId,
    required this.name,
    this.description,
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
    this.lat,
    this.lng,
    this.availableRooms,
    this.facilities = const [],
    this.roomHighlight,
    this.cancellationPolicy,
  });

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    List<String> parsedImages = [];
    if (rawImages is List) {
      parsedImages = rawImages.map((e) => e.toString()).toList();
    }

    final rawFacilities = json['facilities'];
    List<HotelFacility> parsedFacilities = [];
    if (rawFacilities is List) {
      parsedFacilities = rawFacilities
          .whereType<Map>()
          .map((f) => HotelFacility.fromJson(Map<String, dynamic>.from(f)))
          .toList();
    }

    final rawRoomHighlight = json['room_highlight'];
    RoomHighlight? parsedRoomHighlight;
    if (rawRoomHighlight is Map) {
      parsedRoomHighlight =
          RoomHighlight.fromJson(Map<String, dynamic>.from(rawRoomHighlight));
    }

    final rawPolicy = json['cancellation_policy'];
    CancellationPolicy? parsedPolicy;
    if (rawPolicy is Map) {
      parsedPolicy =
          CancellationPolicy.fromJson(Map<String, dynamic>.from(rawPolicy));
    }

    return HotelModel(
      hotelId: (json['hotel_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? 'Khách sạn chưa đặt tên',
      description: json['description']?.toString(),
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
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      availableRooms: (json['available_rooms'] as num?)?.toInt(),
      facilities: parsedFacilities,
      roomHighlight: parsedRoomHighlight,
      cancellationPolicy: parsedPolicy,
    );
  }

  Map<String, dynamic> toJson() => {
        'hotel_id': hotelId,
        'name': name,
        'description': description,
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
        'lat': lat,
        'lng': lng,
        'available_rooms': availableRooms,
        'facilities': facilities.map((f) => f.toJson()).toList(),
        'room_highlight': roomHighlight?.toJson(),
        'cancellation_policy': cancellationPolicy?.toJson(),
      };

  @override
  List<Object?> get props => [
        hotelId,
        name,
        description,
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
        lat,
        lng,
        availableRooms,
        facilities,
        roomHighlight,
        cancellationPolicy,
      ];
}

/// Model tiện nghi khách sạn từ Backend.
class HotelFacility extends Equatable {
  final String id;
  final String name;
  final String? icon;
  final String? type;

  const HotelFacility({
    required this.id,
    required this.name,
    this.icon,
    this.type,
  });

  factory HotelFacility.fromJson(Map<String, dynamic> json) {
    return HotelFacility(
      id: (json['id'] ?? json['facility_id'] ?? '').toString(),
      name: (json['name'] ?? json['facility_name'] ?? '').toString(),
      icon: json['icon']?.toString(),
      type: json['type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'type': type,
      };

  @override
  List<Object?> get props => [id, name, icon, type];
}

/// Model thông tin phòng nổi bật của khách sạn từ Backend.
class RoomHighlight extends Equatable {
  final String roomTypeId;
  final String name;
  final String bedType;
  final String roomSize;
  final int standardBeds;
  final int standardCapacity;
  final bool hasExtraBed;
  final int extraBedCapacity;
  final int maxCapacity;

  const RoomHighlight({
    required this.roomTypeId,
    required this.name,
    this.bedType = '1 giường đôi cực lớn',
    this.roomSize = '38 m²',
    this.standardBeds = 1,
    this.standardCapacity = 2,
    this.hasExtraBed = true,
    this.extraBedCapacity = 1,
    this.maxCapacity = 3,
  });

  factory RoomHighlight.fromJson(Map<String, dynamic> json) {
    return RoomHighlight(
      roomTypeId: (json['room_type_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      bedType: (json['bed_type'] ?? '1 giường đôi cực lớn').toString(),
      roomSize: (json['room_size'] ?? '38 m²').toString(),
      standardBeds: (json['standard_beds'] as num?)?.toInt() ?? 1,
      standardCapacity: (json['standard_capacity'] as num?)?.toInt() ?? 2,
      hasExtraBed: json['has_extra_bed'] == true,
      extraBedCapacity: (json['extra_bed_capacity'] as num?)?.toInt() ?? 1,
      maxCapacity: (json['max_capacity'] as num?)?.toInt() ?? 3,
    );
  }

  Map<String, dynamic> toJson() => {
        'room_type_id': roomTypeId,
        'name': name,
        'bed_type': bedType,
        'room_size': roomSize,
        'standard_beds': standardBeds,
        'standard_capacity': standardCapacity,
        'has_extra_bed': hasExtraBed,
        'extra_bed_capacity': extraBedCapacity,
        'max_capacity': maxCapacity,
      };

  @override
  List<Object?> get props => [
        roomTypeId,
        name,
        bedType,
        roomSize,
        standardBeds,
        standardCapacity,
        hasExtraBed,
        extraBedCapacity,
        maxCapacity,
      ];
}

/// Model chính sách hủy phòng từ Backend.
class CancellationPolicy extends Equatable {
  final int freeBeforeHours;
  final String description;

  const CancellationPolicy({
    this.freeBeforeHours = 48,
    this.description = 'Miễn phí hủy phòng trước 48h (hoàn tiền 100%)',
  });

  factory CancellationPolicy.fromJson(Map<String, dynamic> json) {
    return CancellationPolicy(
      freeBeforeHours: (json['free_before_hours'] ??
              json['free_cancel_before_hours'] as num?)
              ?.toInt() ??
          48,
      description: (json['description'] ??
              'Miễn phí hủy phòng trước 48h (hoàn tiền 100%)')
          .toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'free_before_hours': freeBeforeHours,
        'description': description,
      };

  @override
  List<Object?> get props => [freeBeforeHours, description];
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
