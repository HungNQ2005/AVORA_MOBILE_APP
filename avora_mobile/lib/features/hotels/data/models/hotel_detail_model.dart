import 'package:equatable/equatable.dart';
import 'room_capacity_helper.dart';

/// Tiện nghi của khách sạn
class HotelFacilityModel extends Equatable {
  final String id;
  final String name;
  final String? type;

  const HotelFacilityModel({
    required this.id,
    required this.name,
    this.type,
  });

  factory HotelFacilityModel.fromJson(Map<String, dynamic> json) {
    return HotelFacilityModel(
      id: (json['id'] ?? json['facility_id'] ?? '').toString(),
      name: json['name']?.toString() ?? 'Tiện ích',
      type: json['type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
      };

  @override
  List<Object?> get props => [id, name, type];
}

/// Chính sách hủy phòng
class CancellationPolicyModel extends Equatable {
  final int? freeCancelBeforeHours;
  final num? penaltyRate;
  final String description;

  const CancellationPolicyModel({
    this.freeCancelBeforeHours,
    this.penaltyRate,
    required this.description,
  });

  factory CancellationPolicyModel.fromJson(Map<String, dynamic> json) {
    return CancellationPolicyModel(
      freeCancelBeforeHours: (json['free_cancel_before_hours'] as num?)?.toInt(),
      penaltyRate: json['penalty_rate'] as num?,
      description: json['description']?.toString() ??
          'Miễn phí hủy phòng trước 24 giờ nhận phòng theo chính sách khách sạn',
    );
  }

  Map<String, dynamic> toJson() => {
        'free_cancel_before_hours': freeCancelBeforeHours,
        'penalty_rate': penaltyRate,
        'description': description,
      };

  @override
  List<Object?> get props => [freeCancelBeforeHours, penaltyRate, description];
}

/// Chi tiết loại phòng và tình trạng phòng trống
class RoomTypeDetailModel extends Equatable {
  final String roomTypeId;
  final String name;
  final String? roomSize;
  final String? bedType;
  final int maxAdults;
  final int maxChildren;
  final int standardBeds;
  final int standardCapacity;
  final bool hasExtraBed;
  final int extraBedCapacity;
  final int maxCapacity;
  final int guestsPerRoom;
  final bool isCapacityExceeded;
  final String? capacityWarning;
  final num defaultPrice;
  final num price;
  final num? originalPrice;
  final int availableRooms;
  final String policyDescription;
  final bool isVip;
  final String? image;

  const RoomTypeDetailModel({
    required this.roomTypeId,
    required this.name,
    this.roomSize,
    this.bedType,
    this.maxAdults = 2,
    this.maxChildren = 0,
    required this.standardBeds,
    required this.standardCapacity,
    required this.hasExtraBed,
    required this.extraBedCapacity,
    required this.maxCapacity,
    this.guestsPerRoom = 2,
    this.isCapacityExceeded = false,
    this.capacityWarning,
    required this.defaultPrice,
    required this.price,
    this.originalPrice,
    this.availableRooms = 1,
    required this.policyDescription,
    this.isVip = false,
    this.image,
  });

  factory RoomTypeDetailModel.fromJson(Map<String, dynamic> json) {
    final bedType = json['bed_type']?.toString();
    final maxAdults = (json['max_adults'] as num?)?.toInt() ?? 2;
    final maxChildren = (json['max_children'] as num?)?.toInt() ?? 0;

    final capDetails = RoomCapacityHelper.getRoomCapacityDetails(
      bedType: bedType,
      maxAdults: maxAdults,
      maxChildren: maxChildren,
    );

    final guestsPerRoom = (json['guests_per_room'] as num?)?.toInt() ?? 2;
    final isExceeded = json['is_capacity_exceeded'] == true ||
        guestsPerRoom > capDetails.maxCapacity;

    final rawPrice = (json['price'] as num?) ?? (json['default_price'] as num?) ?? 0;
    final origPrice = json['original_price'] != null
        ? (json['original_price'] as num)
        : (rawPrice > 0 ? (rawPrice * 1.2).round() : null);

    return RoomTypeDetailModel(
      roomTypeId: (json['room_type_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? json['type_name']?.toString() ?? 'Phòng tiêu chuẩn',
      roomSize: json['room_size']?.toString(),
      bedType: bedType,
      maxAdults: maxAdults,
      maxChildren: maxChildren,
      standardBeds: (json['standard_beds'] as num?)?.toInt() ?? capDetails.standardBeds,
      standardCapacity: (json['standard_capacity'] as num?)?.toInt() ?? capDetails.standardCapacity,
      hasExtraBed: json['has_extra_bed'] == true || capDetails.hasExtraBed,
      extraBedCapacity: (json['extra_bed_capacity'] as num?)?.toInt() ?? capDetails.extraBedCapacity,
      maxCapacity: (json['max_capacity'] as num?)?.toInt() ?? capDetails.maxCapacity,
      guestsPerRoom: guestsPerRoom,
      isCapacityExceeded: isExceeded,
      capacityWarning: json['capacity_warning']?.toString() ??
          (isExceeded
              ? 'Không được cho phép booking $guestsPerRoom người vào phòng này! Phòng này tối đa ${capDetails.maxCapacity} người.'
              : null),
      defaultPrice: (json['default_price'] as num?) ?? rawPrice,
      price: rawPrice,
      originalPrice: origPrice,
      availableRooms: (json['available_rooms'] as num?)?.toInt() ?? 1,
      policyDescription: json['policy_description']?.toString() ??
          'Miễn phí hủy phòng theo chính sách khách sạn',
      isVip: json['is_vip'] == true,
      image: json['image']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        roomTypeId,
        name,
        roomSize,
        bedType,
        maxAdults,
        maxChildren,
        standardBeds,
        standardCapacity,
        hasExtraBed,
        extraBedCapacity,
        maxCapacity,
        guestsPerRoom,
        isCapacityExceeded,
        capacityWarning,
        defaultPrice,
        price,
        originalPrice,
        availableRooms,
        policyDescription,
        isVip,
        image,
      ];
}

/// Đánh giá từ khách hàng
class ReviewModel extends Equatable {
  final String reviewId;
  final String guestName;
  final double score;
  final String comment;
  final String? createdAt;

  const ReviewModel({
    required this.reviewId,
    required this.guestName,
    required this.score,
    required this.comment,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewId: (json['review_id'] ?? json['id'] ?? '').toString(),
      guestName:
        (json['reviewer_name'] ?? json['guest_name'])?.toString() ??
        'Khách hàng Avora',
      score: ((json['rating_score'] ?? json['score']) as num?)?.toDouble() ??
        9.0,
      comment: json['comment']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
    );
  }

  @override
  List<Object?> get props => [reviewId, guestName, score, comment, createdAt];
}

/// Model chi tiết đầy đủ của khách sạn (GET /api/hotels/:id)
class HotelDetailModel extends Equatable {
  final String hotelId;
  final String name;
  final String description;
  final String address;
  final String fullAddress;
  final String? wardName;
  final String? districtName;
  final String? cityName;
  final int starQuality;
  final double starRating;
  final int reviewsCount;
  final String scoreLabel;
  final String hotelStatus;
  final double? lat;
  final double? lng;
  final List<HotelFacilityModel> facilities;
  final List<String> images;
  final String? thumbnail;
  final CancellationPolicyModel? cancellationPolicy;
  final List<RoomTypeDetailModel> rooms;
  final List<ReviewModel> reviews;

  const HotelDetailModel({
    required this.hotelId,
    required this.name,
    this.description = '',
    this.address = '',
    this.fullAddress = '',
    this.wardName,
    this.districtName,
    this.cityName,
    this.starQuality = 5,
    this.starRating = 9.0,
    this.reviewsCount = 0,
    this.scoreLabel = 'Xuất sắc',
    this.hotelStatus = 'ACTIVE',
    this.lat,
    this.lng,
    this.facilities = const [],
    this.images = const [],
    this.thumbnail,
    this.cancellationPolicy,
    this.rooms = const [],
    this.reviews = const [],
  });

  factory HotelDetailModel.fromJson(Map<String, dynamic> json) {
    // Phân tích danh sách hình ảnh
    final rawImages = json['images'];
    List<String> parsedImages = [];
    if (rawImages is List) {
      parsedImages = rawImages.map((e) => e.toString()).toList();
    }
    if (parsedImages.isEmpty && json['thumbnail'] != null) {
      parsedImages.add(json['thumbnail'].toString());
    }

    // Phân tích danh sách tiện nghi
    final rawFacilities = json['facilities'];
    List<HotelFacilityModel> parsedFacilities = [];
    if (rawFacilities is List) {
      parsedFacilities = rawFacilities
          .map((f) => HotelFacilityModel.fromJson(Map<String, dynamic>.from(f as Map)))
          .toList();
    }

    // Phân tích danh sách phòng
    final rawRooms = json['rooms'];
    List<RoomTypeDetailModel> parsedRooms = [];
    if (rawRooms is List) {
      parsedRooms = rawRooms
          .map((r) => RoomTypeDetailModel.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    }

    // Phân tích danh sách đánh giá
    final rawReviews = json['reviews'];
    List<ReviewModel> parsedReviews = [];
    if (rawReviews is List) {
      parsedReviews = rawReviews
          .map((rev) => ReviewModel.fromJson(Map<String, dynamic>.from(rev as Map)))
          .toList();
    }

    // Phân tích chính sách hủy
    CancellationPolicyModel? parsedPolicy;
    if (json['cancellation_policy'] is Map) {
      parsedPolicy = CancellationPolicyModel.fromJson(
        Map<String, dynamic>.from(json['cancellation_policy'] as Map),
      );
    }

    return HotelDetailModel(
      hotelId: (json['hotel_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? 'Khách sạn chưa đặt tên',
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      fullAddress: json['full_address']?.toString() ?? json['address']?.toString() ?? '',
      wardName: json['ward_name']?.toString(),
      districtName: json['district_name']?.toString(),
      cityName: json['city_name']?.toString(),
      starQuality: (json['star_quality'] as num?)?.toInt() ?? 5,
      starRating: (json['star_rating'] as num?)?.toDouble() ?? 9.0,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? parsedReviews.length,
      scoreLabel: json['score_label']?.toString() ?? 'Xuất sắc',
      hotelStatus: json['hotel_status']?.toString() ?? 'ACTIVE',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      facilities: parsedFacilities,
      images: parsedImages,
      thumbnail: json['thumbnail']?.toString() ?? (parsedImages.isNotEmpty ? parsedImages.first : null),
      cancellationPolicy: parsedPolicy,
      rooms: parsedRooms,
      reviews: parsedReviews,
    );
  }

  @override
  List<Object?> get props => [
        hotelId,
        name,
        description,
        address,
        fullAddress,
        wardName,
        districtName,
        cityName,
        starQuality,
        starRating,
        reviewsCount,
        scoreLabel,
        hotelStatus,
        lat,
        lng,
        facilities,
        images,
        thumbnail,
        cancellationPolicy,
        rooms,
        reviews,
      ];
}
