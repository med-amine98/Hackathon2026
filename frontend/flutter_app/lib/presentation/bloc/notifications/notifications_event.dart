// lib/presentation/bloc/notifications/notifications_event.dart

part of 'notifications_bloc.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotificationsEvent extends NotificationsEvent {
  const LoadNotificationsEvent();
}

class MarkNotificationAsReadEvent extends NotificationsEvent {
  final String id;
  
  const MarkNotificationAsReadEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class MarkAllNotificationsAsReadEvent extends NotificationsEvent {
  const MarkAllNotificationsAsReadEvent();
}

class DeleteNotificationEvent extends NotificationsEvent {
  final String id;
  
  const DeleteNotificationEvent(this.id);

  @override
  List<Object?> get props => [id];
}