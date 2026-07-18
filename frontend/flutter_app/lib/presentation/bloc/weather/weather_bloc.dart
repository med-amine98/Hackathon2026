// lib/presentation/bloc/weather/weather_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ai_insurance_advisor/services/weather_service.dart';

part 'weather_event.dart';
part 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  WeatherBloc() : super(const WeatherInitial()) {
    on<LoadWeatherEvent>(_onLoadWeather);
    on<RefreshWeatherEvent>(_onRefreshWeather);
    on<ChangeCityEvent>(_onChangeCity);
  }

  Future<void> _onLoadWeather(
    LoadWeatherEvent event,
    Emitter<WeatherState> emit,
  ) async {
    emit(const WeatherLoading());
    try {
      final data = await WeatherService.getWeather(
        latitude: event.latitude,
        longitude: event.longitude,
      );
      
      emit(WeatherLoaded(
        temperature: (data['temperature'] as num).toDouble(),
        feelsLike: (data['feels_like'] as num).toDouble(),
        humidity: (data['humidity'] as num).toDouble(),
        pressure: (data['pressure'] as num).toDouble(),
        condition: data['condition'] as String,
        description: data['description'] as String,
        icon: data['icon'] as String,
        windSpeed: (data['wind_speed'] as num).toDouble(),
        windDeg: (data['wind_deg'] as num).toDouble(),
        city: data['city'] as String,
        country: data['country'] as String,
        weatherCode: data['weathercode'] as int,
        lastUpdate: data['lastUpdate'] as String,
      ));
    } catch (e) {
      emit(WeatherError(e.toString()));
    }
  }

  Future<void> _onRefreshWeather(
    RefreshWeatherEvent event,
    Emitter<WeatherState> emit,
  ) async {
    final currentState = state;
    if (currentState is WeatherLoaded) {
      final coords = WeatherService.tunisianCities[currentState.city];
      if (coords != null) {
        add(LoadWeatherEvent(
          latitude: coords['lat']!,
          longitude: coords['lon']!,
        ));
      }
    } else {
      final coords = WeatherService.tunisianCities['Tunis']!;
      add(LoadWeatherEvent(
        latitude: coords['lat']!,
        longitude: coords['lon']!,
      ));
    }
  }

  Future<void> _onChangeCity(
    ChangeCityEvent event,
    Emitter<WeatherState> emit,
  ) async {
    emit(const WeatherLoading());
    try {
      final data = await WeatherService.getWeather(
        latitude: event.latitude,
        longitude: event.longitude,
      );
      
      emit(WeatherLoaded(
        temperature: (data['temperature'] as num).toDouble(),
        feelsLike: (data['feels_like'] as num).toDouble(),
        humidity: (data['humidity'] as num).toDouble(),
        pressure: (data['pressure'] as num).toDouble(),
        condition: data['condition'] as String,
        description: data['description'] as String,
        icon: data['icon'] as String,
        windSpeed: (data['wind_speed'] as num).toDouble(),
        windDeg: (data['wind_deg'] as num).toDouble(),
        city: event.cityName,
        country: data['country'] as String,
        weatherCode: data['weathercode'] as int,
        lastUpdate: data['lastUpdate'] as String,
      ));
    } catch (e) {
      emit(WeatherError(e.toString()));
    }
  }
}