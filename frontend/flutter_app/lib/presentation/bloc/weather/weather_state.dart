part of 'weather_bloc.dart';

abstract class WeatherState extends Equatable {
  const WeatherState();
  
  @override
  List<Object?> get props => [];
}

class WeatherInitial extends WeatherState {
  const WeatherInitial();
}

class WeatherLoading extends WeatherState {
  const WeatherLoading();
}

class WeatherLoaded extends WeatherState {
  final double temperature;
  final double feelsLike;
  final double humidity;
  final double pressure;
  final String condition;
  final String description;
  final String icon;
  final double windSpeed;
  final double windDeg;
  final String city;
  final String country;
  final int weatherCode;
  final String lastUpdate;

  const WeatherLoaded({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
    required this.condition,
    required this.description,
    required this.icon,
    required this.windSpeed,
    required this.windDeg,
    required this.city,
    required this.country,
    required this.weatherCode,
    required this.lastUpdate,
  });

  @override
  List<Object?> get props => [
    temperature, feelsLike, humidity, pressure, condition,
    description, icon, windSpeed, windDeg, city, country,
    weatherCode, lastUpdate
  ];
}

class WeatherError extends WeatherState {
  final String message;

  const WeatherError(this.message);

  @override
  List<Object?> get props => [message];
}