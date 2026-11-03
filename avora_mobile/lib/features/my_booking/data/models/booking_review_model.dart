import 'package:equatable/equatable.dart';

class BookingReviewModel extends Equatable {
  final String reviewId;
  final int ratingScore;
  final String comment;
  final String? createdAt;
  final bool canEdit;

  const BookingReviewModel({
    required this.reviewId,
    required this.ratingScore,
    required this.comment,
    this.createdAt,
    this.canEdit = false,
  });

  factory BookingReviewModel.fromJson(Map<String, dynamic> json) {
    return BookingReviewModel(
      reviewId: (json['review_id'] ?? '').toString(),
      ratingScore: (json['rating_score'] as num?)?.toInt() ?? 8,
      comment: (json['comment'] ?? '').toString(),
      createdAt: json['created_at']?.toString(),
      canEdit: json['can_edit'] == true || json['can_manage'] == true,
    );
  }

  @override
  List<Object?> get props => [
    reviewId,
    ratingScore,
    comment,
    createdAt,
    canEdit,
  ];
}

class BookingReviewAvailability extends Equatable {
  final BookingReviewModel? review;
  final bool canCreate;
  final bool unavailable;

  const BookingReviewAvailability({
    this.review,
    this.canCreate = false,
    this.unavailable = false,
  });

  factory BookingReviewAvailability.fromJson(Map<String, dynamic> json) {
    final rawReview = json['review'];
    return BookingReviewAvailability(
      review: rawReview is Map
          ? BookingReviewModel.fromJson(Map<String, dynamic>.from(rawReview))
          : null,
      canCreate: json['can_create'] == true,
      unavailable: json['unavailable'] == true,
    );
  }

  @override
  List<Object?> get props => [review, canCreate, unavailable];
}
