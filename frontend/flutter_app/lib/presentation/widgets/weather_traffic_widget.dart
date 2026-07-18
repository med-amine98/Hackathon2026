// lib/presentation/widgets/weather_traffic_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/weather/weather_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/traffic/traffic_bloc.dart';
import 'package:ai_insurance_advisor/services/weather_service.dart';
import 'package:ai_insurance_advisor/services/traffic_service.dart';
import 'package:ai_insurance_advisor/app/theme.dart';

class WeatherTrafficWidget extends StatefulWidget {
  const WeatherTrafficWidget({super.key});

  @override
  State<WeatherTrafficWidget> createState() => _WeatherTrafficWidgetState();
}

class _WeatherTrafficWidgetState extends State<WeatherTrafficWidget> {
  String _selectedCity = 'Tunis';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final coords = WeatherService.tunisianCities[_selectedCity]!;
    context.read<WeatherBloc>().add(LoadWeatherEvent(
      latitude: coords['lat']!,
      longitude: coords['lon']!,
    ));
    context.read<TrafficBloc>().add(LoadTrafficEvent(
      lat: coords['lat']!,
      lon: coords['lon']!,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // En-tête avec sélecteur de ville
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                DropdownButton<String>(
                  value: _selectedCity,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, size: 16),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A2E),
                  ),
                  items: WeatherService.tunisianCities.keys.map((city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (newCity) {
                    if (newCity != null) {
                      setState(() {
                        _selectedCity = newCity;
                      });
                      _loadData();
                    }
                  },
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Actualiser',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Météo
                Expanded(
                  child: BlocBuilder<WeatherBloc, WeatherState>(
                    builder: (context, state) {
                      if (state is WeatherLoading) {
                        return _buildLoading('Météo');
                      }
                      if (state is WeatherLoaded) {
                        return _buildWeatherCard(state);
                      }
                      if (state is WeatherError) {
                        return _buildErrorWidget('🌤️', state.message);
                      }
                      return _buildWeatherCardDefault();
                    },
                  ),
                ),
                const VerticalDivider(width: 16, thickness: 1),
                // Trafic
                Expanded(
                  child: BlocBuilder<TrafficBloc, TrafficState>(
                    builder: (context, state) {
                      if (state is TrafficLoading) {
                        return _buildLoading('Trafic');
                      }
                      if (state is TrafficLoaded) {
                        return _buildTrafficCard(state);
                      }
                      if (state is TrafficError) {
                        return _buildErrorWidget('🚦', state.message);
                      }
                      return _buildTrafficCardDefault();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // WEATHER CARD - AVEC OPENWEATHER
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildWeatherCard(WeatherLoaded state) {
    final iconUrl = WeatherService.getWeatherIcon(state.icon);
    
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            iconUrl,
            width: 56,
            height: 56,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.wb_sunny, size: 30, color: Colors.grey),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFallbackIcon(state.weatherCode),
                  size: 30,
                  color: Colors.orange,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${state.temperature.toStringAsFixed(1)}°C',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        Text(
          state.condition,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          state.description,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInfoChip(
              icon: Icons.water_drop,
              value: '${state.humidity.toStringAsFixed(0)}%',
              color: Colors.blue.shade300,
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              icon: Icons.air,
              value: '${state.windSpeed.toStringAsFixed(0)} km/h',
              color: Colors.grey.shade400,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${state.city}, ${state.country}',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[400],
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          '🔄 ${_formatTimeAgo(DateTime.parse(state.lastUpdate))}',
          style: TextStyle(
            fontSize: 8,
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherCardDefault() {
    return Column(
      children: [
        const Icon(Icons.wb_sunny, size: 40, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          '--°C',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        Text(
          'Chargement...',
          style: TextStyle(color: Colors.grey[600], fontSize: 11),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TRAFFIC CARD
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildTrafficCard(TrafficLoaded state) {
    return Column(
      children: [
        Icon(
          state.isCongested ? Icons.traffic : Icons.emoji_transportation,
          size: 28,
          color: state.isCongested ? Colors.red : Colors.green,
        ),
        const SizedBox(height: 4),
        Text(
          state.trafficLevel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: state.isCongested ? Colors.red : Colors.green,
          ),
        ),
        Text(
          state.location,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        if (state.totalDelay > 0)
          Text(
            'Retard: ${state.totalDelay} min',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        if (state.incidentCount > 0)
          Text(
            '${state.incidentCount} incident(s)',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        Text(
          '🔄 ${_formatTimeAgo(DateTime.parse(state.lastUpdate))}',
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildTrafficCardDefault() {
    return Column(
      children: [
        const Icon(Icons.traffic, size: 28, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          'Chargement...',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LOADING & ERROR
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildLoading(String label) {
    return Column(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(height: 4),
        Text(
          'Chargement $label...',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String icon, String message) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          message,
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildInfoChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFallbackIcon(int weatherCode) {
    if (weatherCode >= 200 && weatherCode < 300) return Icons.flash_on;
    if (weatherCode >= 300 && weatherCode < 600) return Icons.grain;
    if (weatherCode >= 600 && weatherCode < 700) return Icons.ac_unit;
    if (weatherCode >= 700 && weatherCode < 800) return Icons.cloud;
    if (weatherCode == 800) return Icons.wb_sunny;
    if (weatherCode > 800) return Icons.cloud_queue;
    return Icons.wb_sunny;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inMinutes < 1) return 'à l\'instant';
    if (difference.inMinutes < 60) return 'il y a ${difference.inMinutes}min';
    if (difference.inHours < 24) return 'il y a ${difference.inHours}h';
    if (difference.inDays < 7) return 'il y a ${difference.inDays}j';
    return 'il y a ${(difference.inDays / 7).floor()}sem';
  }
}