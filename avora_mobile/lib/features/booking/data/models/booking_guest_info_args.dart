import 'package:equatable/equatable.dart';
import 'package:avora_mobile/features/hotels/data/models/hotel_detail_model.dart';

/// Arguments truyền vào màn hình nhập thông tin khách lưu trú
class BookingGuestInfoArgs extends Equatable {
  final HotelDetailModel? hotel;
  final RoomTypeDetailModel? room;
  final String hotelName;
  final String roomName;
  final String stayDates;
  final int nights;
  final int adults;
  final int children;
  final int rooms;
  final num? pricePerNight;
  final num? totalPrice;

  const BookingGuestInfoArgs({
    this.hotel,
    this.room,
    this.hotelName = 'Avora Grand Resort & Spa',
    this.roomName = 'Phòng Deluxe Hướng Biển',
    this.stayDates = 'Hôm nay - Ngày mai',
    this.nights = 1,
    this.adults = 2,
    this.children = 0,
    this.rooms = 1,
    this.pricePerNight,
    this.totalPrice,
  });

  @override
  List<Object?> get props => [
        hotel,
        room,
        hotelName,
        roomName,
        stayDates,
        nights,
        adults,
        children,
        rooms,
        pricePerNight,
        totalPrice,
      ];
}
