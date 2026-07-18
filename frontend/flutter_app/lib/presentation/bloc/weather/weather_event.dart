// lib/presentation/bloc/weather/weather_event.dart

part of 'weather_bloc.dart';

abstract class WeatherEvent extends Equatable {
  const WeatherEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadWeatherEvent extends WeatherEvent {
  final double latitude;
  final double longitude;
  
  const LoadWeatherEvent({
    required this.latitude,
    required this.longitude,
  });
  
  @override
  List<Object?> get props => [latitude, longitude];
}

class RefreshWeatherEvent extends WeatherEvent {
  const RefreshWeatherEvent();
}

class ChangeCityEvent extends WeatherEvent {
  final String cityName;
  final double latitude;
  final double longitude;
  
  const ChangeCityEvent({
    required this.cityName,
    required this.latitude,
    required this.longitude,
  });
  
  @override
  List<Object?> get props => [cityName, latitude, longitude];
}