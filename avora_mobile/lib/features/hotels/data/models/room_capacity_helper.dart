import 'dart:math';

/// Room Capacity & Bed Configuration Business Logic
/// Đồng bộ 100% với utils/roomCapacityHelper.js từ Web version.
///
/// Rules:
/// - 2 giường tiêu chuẩn × 2 người = 4 người
/// - Có thêm 1 giường phụ × 1 người = tối đa 5 người
/// - Không được cho phép booking 6 người vào phòng này
/// - Sức chứa tối đa của 1 phòng trong toàn hệ thống là 5 người
class RoomCapacityHelper {
  RoomCapacityHelper._();

  static const int maxRoomCapacity = 5;

  /// Phân tích cấu hình giường và tính toán sức chứa phòng
  static RoomCapacityDetails getRoomCapacityDetails({
    String? bedType,
    int? maxAdults,
    int? maxChildren,
  }) {
    final bedTypeStr = (bedType ?? '').trim().toLowerCase();
    final parsedMaxAdults = maxAdults ?? 2;

    int bedCount = 1;
    final firstCharMatch = RegExp(r'^(\d+)').firstMatch(bedTypeStr);
    if (firstCharMatch != null) {
      bedCount = int.tryParse(firstCharMatch.group(1)!) ?? 1;
    } else if (bedTypeStr.contains('hai giường') || bedTypeStr.contains('twin')) {
      bedCount = 2;
    }

    final isSingle = bedTypeStr.contains('single') || bedTypeStr.contains('đơn');

    int standardCapacity = 2;
    int standardBeds = 1;

    if (isSingle) {
      standardBeds = bedCount;
      standardCapacity = bedCount;
    } else if (bedCount >= 2 ||
        parsedMaxAdults >= 4 ||
        bedTypeStr.contains('2 x') ||
        bedTypeStr.contains('2 giường')) {
      standardBeds = 2;
      standardCapacity = 4;
    } else {
      standardBeds = 1;
      standardCapacity = 2;
    }

    final hasExtraBed = standardCapacity >= 2;
    final extraBedCapacity = hasExtraBed ? 1 : 0;
    final computedMaxCapacity = min(maxRoomCapacity, standardCapacity + extraBedCapacity);

    return RoomCapacityDetails(
      standardBeds: standardBeds,
      standardCapacity: standardCapacity,
      hasExtraBed: hasExtraBed,
      extraBedCapacity: extraBedCapacity,
      maxCapacity: computedMaxCapacity,
      bedDescription: standardBeds == 2
          ? '2 giường tiêu chuẩn (4 người) + 1 giường phụ (1 người)'
          : '1 giường đôi tiêu chuẩn (2 người) + 1 giường phụ (1 người)',
    );
  }

  /// Tính số phòng tối thiểu cần thiết để chứa tổng số khách
  static int getMinRoomsRequired(int totalGuests) {
    final guests = max(1, totalGuests);
    return (guests / maxRoomCapacity).ceil();
  }

  /// Kiểm tra số phòng và tổng số khách có hợp lệ hay không
  static CapacityValidationResult validateGuestRoomCapacity(int totalGuests, int rooms) {
    final guests = max(1, totalGuests);
    final roomCount = max(1, rooms);
    final guestsPerRoom = (guests / roomCount).ceil();
    final minRooms = (guests / maxRoomCapacity).ceil();

    if (guestsPerRoom > maxRoomCapacity) {
      return CapacityValidationResult(
        isValid: false,
        guestsPerRoom: guestsPerRoom,
        minRooms: minRooms,
        message:
            'Không có loại phòng nào như vậy. Sức chứa tối đa của 1 phòng là 5 người (2 giường tiêu chuẩn × 2 người = 4 người + 1 giường phụ × 1 người = 5 người). Bạn đang chọn $guestsPerRoom người/phòng. Cần tối thiểu $minRooms phòng.',
      );
    }

    return CapacityValidationResult(
      isValid: true,
      guestsPerRoom: guestsPerRoom,
      minRooms: minRooms,
      message: '',
    );
  }
}

class RoomCapacityDetails {
  final int standardBeds;
  final int standardCapacity;
  final bool hasExtraBed;
  final int extraBedCapacity;
  final int maxCapacity;
  final String bedDescription;

  const RoomCapacityDetails({
    required this.standardBeds,
    required this.standardCapacity,
    required this.hasExtraBed,
    required this.extraBedCapacity,
    required this.maxCapacity,
    required this.bedDescription,
  });
}

class CapacityValidationResult {
  final bool isValid;
  final int guestsPerRoom;
  final int minRooms;
  final String message;

  const CapacityValidationResult({
    required this.isValid,
    required this.guestsPerRoom,
    required this.minRooms,
    required this.message,
  });
}
