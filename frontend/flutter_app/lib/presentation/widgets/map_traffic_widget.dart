// lib/presentation/widgets/map_traffic_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ai_insurance_advisor/presentation/bloc/traffic/traffic_bloc.dart';

class MapTrafficWidget extends StatefulWidget {
  const MapTrafficWidget({super.key});

  @override
  State<MapTrafficWidget> createState() => _MapTrafficWidgetState();
}

class _MapTrafficWidgetState extends State<MapTrafficWidget> {
  final MapController _mapController = MapController();
  late LatLng _currentPosition;
  List<Marker> _markers = [];
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _currentPosition = const LatLng(36.8065, 10.1815);
    context.read<TrafficBloc>().add(LoadTrafficEvent(
      lat: _currentPosition.latitude,
      lon: _currentPosition.longitude,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _buildTrafficHeader(),
            SizedBox(
              height: 280,
              child: Stack(
                children: [
                  _buildMap(),
                  if (!_isMapReady)
                    const Center(child: CircularProgressIndicator()),
                  _buildTrafficLegend(),
                ],
              ),
            ),
            _buildTrafficDetails(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MAP
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition,
        initialZoom: 13,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        onMapReady: () {
          setState(() {
            _isMapReady = true;
            _addTrafficMarkers();
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.insurance.advisor',
        ),
        MarkerLayer(markers: _markers),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TRAFFIC HEADER
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildTrafficHeader() {
    return BlocBuilder<TrafficBloc, TrafficState>(
      builder: (context, state) {
        String status;
        Color color;
        IconData icon;
        String details;

        if (state is TrafficLoading) {
          status = 'Chargement...';
          color = Colors.orange;
          icon = Icons.hourglass_empty;
          details = 'Récupération des données...';
        } else if (state is TrafficLoaded) {
          if (state.isCongested) {
            status = 'Trafic dense';
            color = Colors.red;
            icon = Icons.traffic;
            details = '${state.incidentCount} incident(s) - Retard: ${state.totalDelay}min';
          } else {
            status = 'Trafic fluide';
            color = Colors.green;
            icon = Icons.emoji_transportation;
            details = 'Aucun incident signalé';
          }
        } else if (state is TrafficError) {
          status = 'Service indisponible';
          color = Colors.grey;
          icon = Icons.error_outline;
          details = state.message;
        } else {
          status = 'En attente...';
          color = Colors.grey;
          icon = Icons.access_time;
          details = 'Veuillez actualiser';
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade100),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      details,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  context.read<TrafficBloc>().add(RefreshTrafficEvent(
                    lat: _currentPosition.latitude,
                    lon: _currentPosition.longitude,
                  ));
                },
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Actualiser',
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TRAFFIC LEGEND
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildTrafficLegend() {
    return Positioned(
      bottom: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem(Colors.red, 'Trafic dense'),
            _buildLegendItem(Colors.orange, 'Trafic modéré'),
            _buildLegendItem(Colors.green, 'Trafic fluide'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TRAFFIC DETAILS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildTrafficDetails() {
    return BlocBuilder<TrafficBloc, TrafficState>(
      builder: (context, state) {
        if (state is! TrafficLoaded) {
          return const SizedBox.shrink();
        }

        if (state.incidents.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            color: Colors.green.shade50,
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ Aucun incident signalé sur votre itinéraire',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(12),
          color: Colors.red.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Text(
                    '⚠️ ${state.incidentCount} incident(s) signalé(s)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...state.incidents.take(3).map((incident) {
                final incidentIcon = incident['icon']?.toString() ?? '⚠️';
                final incidentType = incident['type']?.toString() ?? 'Incident';
                final incidentDesc = incident['description']?.toString() ?? '';
                final incidentDelay = incident['delay'] as int? ?? 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        incidentIcon,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              incidentType,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              incidentDesc,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (incidentDelay > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '+${incidentDelay}min',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MAP MARKERS
  // ═══════════════════════════════════════════════════════════════════════

  void _addTrafficMarkers() {
    _markers = [
      // Position actuelle
      Marker(
        point: _currentPosition,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const CircleAvatar(
            radius: 14,
            backgroundColor: Colors.blue,
            child: Icon(Icons.my_location, size: 16, color: Colors.white),
          ),
        ),
      ),
      // Incident 1
      Marker(
        point: LatLng(36.8200, 10.1700),
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
          child: const CircleAvatar(
            radius: 14,
            backgroundColor: Colors.red,
            child: Icon(Icons.warning, size: 16, color: Colors.white),
          ),
        ),
      ),
      // Incident 2
      Marker(
        point: LatLng(36.7900, 10.2000),
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
          child: const CircleAvatar(
            radius: 14,
            backgroundColor: Colors.orange,
            child: Icon(Icons.construction, size: 16, color: Colors.white),
          ),
        ),
      ),
    ];
  }
}