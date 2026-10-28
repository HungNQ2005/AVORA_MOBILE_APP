import 'package:equatable/equatable.dart';

class DestinationWeather extends Equatable {
  final String cityId;
  final String cityName;
  final int temperature;
  final String condition;
  final String weatherCode; // 'sunny', 'cloudy', 'rain', 'cool'
  final int humidity;
  final int uvIndex;
  final String clothingAdvice;
  final List<String> travelTips;

  const DestinationWeather({
    required this.cityId,
    required this.cityName,
    required this.temperature,
    required this.condition,
    required this.weatherCode,
    this.humidity = 70,
    this.uvIndex = 6,
    required this.clothingAdvice,
    this.travelTips = const [],
  });

  @override
  List<Object?> get props => [
        cityId,
        cityName,
        temperature,
        condition,
        weatherCode,
        humidity,
        uvIndex,
        clothingAdvice,
        travelTips,
      ];
}
