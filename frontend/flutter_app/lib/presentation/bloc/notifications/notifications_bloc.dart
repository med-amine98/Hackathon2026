import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc() : super(const NotificationsInitial()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<MarkNotificationReadEvent>(_onMarkRead);
    on<ClearNotificationsEvent>(_onClearNotifications);
  }

  Future<void> _onLoadNotifications(
    LoadNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(const NotificationsLoading());
    try {
      // ✅ CORRIGÉ : Type explicite pour Future.delayed
      await Future<void>.delayed(const Duration(seconds: 1));
      
      final notifications = [
        {
          'id': '1',
          'icon': Icons.warning,
          'color': Colors.orange,
          'title': 'Entretien recommandé',
          'message': 'Votre véhicule a parcouru 15 000 km',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          'read': false,
        },
        {
          'id': '2',
          'icon': Icons.cloud,
          'color': Colors.blue,
          'title': 'Météo aujourd\'hui',
          'message': '🌤️ 28°C - Beau temps',
          'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
          'read': false,
        },
        {
          'id': '3',
          'icon': Icons.traffic,
          'color': Colors.green,
          'title': 'Circulation',
          'message': '🟢 Trafic fluide sur l\'autoroute',
          'timestamp': DateTime.now().subtract(const Duration(hours: 8)),
          'read': true,
        },
      ];
      
      emit(NotificationsLoaded(notifications));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  void _onMarkRead(
    MarkNotificationReadEvent event,
    Emitter<NotificationsState> emit,
  ) {
    final currentState = state;
    if (currentState is NotificationsLoaded) {
      final updated = currentState.notifications.map((n) {
        if (n['id'] == event.id) {
          return {...n, 'read': true};
        }
        return n;
      }).toList();
      emit(NotificationsLoaded(updated));
    }
  }

  void _onClearNotifications(
    ClearNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) {
    emit(const NotificationsLoaded([]));
  }
}