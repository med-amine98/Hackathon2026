// lib/presentation/bloc/notifications/notifications_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ai_insurance_advisor/data/models/notification_model.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc() : super(const NotificationsInitial()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<MarkNotificationAsReadEvent>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsReadEvent>(_onMarkAllNotificationsAsRead);
    on<DeleteNotificationEvent>(_onDeleteNotification);
  }

  Future<void> _onLoadNotifications(
    LoadNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(const NotificationsLoading());
    try {
      // Simuler des données de notification
      await Future.delayed(const Duration(milliseconds: 500));
      
      final notifications = [
        NotificationModel(
          id: '1',
          title: '🔔 Nouveau message',
          message: 'Vous avez reçu un nouveau message de votre conseiller.',
          type: 'info',
          date: DateTime.now().subtract(const Duration(minutes: 5)),
          isRead: false,
        ),
        NotificationModel(
          id: '2',
          title: '✅ Déclaration traitée',
          message: 'Votre déclaration #1234 a été traitée avec succès.',
          type: 'success',
          date: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: false,
        ),
        NotificationModel(
          id: '3',
          title: '⚠️ Rappel',
          message: 'N\'oubliez pas de renouveler votre assurance avant le 15/07/2026.',
          type: 'warning',
          date: DateTime.now().subtract(const Duration(days: 1)),
          isRead: true,
        ),
        NotificationModel(
          id: '4',
          title: '📄 Document disponible',
          message: 'Votre attestation d\'assurance est disponible en téléchargement.',
          type: 'info',
          date: DateTime.now().subtract(const Duration(days: 3)),
          isRead: true,
        ),
        NotificationModel(
          id: '5',
          title: '🔒 Sécurité',
          message: 'Une nouvelle connexion a été détectée sur votre compte.',
          type: 'error',
          date: DateTime.now().subtract(const Duration(days: 5)),
          isRead: true,
        ),
      ];
      
      emit(NotificationsLoaded(notifications));
    } catch (e) {
      emit(NotificationsError('Erreur lors du chargement des notifications: $e'));
    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      final updatedNotifications = currentState.notifications.map((notification) {
        if (notification.id == event.id) {
          return NotificationModel(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            type: notification.type,
            date: notification.date,
            isRead: true,
          );
        }
        return notification;
      }).toList();
      
      emit(NotificationsLoaded(updatedNotifications));
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      final updatedNotifications = currentState.notifications.map((notification) {
        return NotificationModel(
          id: notification.id,
          title: notification.title,
          message: notification.message,
          type: notification.type,
          date: notification.date,
          isRead: true,
        );
      }).toList();
      
      emit(NotificationsLoaded(updatedNotifications));
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      final updatedNotifications = currentState.notifications
          .where((notification) => notification.id != event.id)
          .toList();
      
      emit(NotificationsLoaded(updatedNotifications));
    }
  }
}