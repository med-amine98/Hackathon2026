part of 'notifications_bloc.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadNotificationsEvent extends NotificationsEvent {
  const LoadNotificationsEvent();
}

class MarkNotificationReadEvent extends NotificationsEvent {
  final String id;
  
  const MarkNotificationReadEvent(this.id);
  
  @override
  List<Object?> get props => [id];
}

class ClearNotificationsEvent extends NotificationsEvent {
  const ClearNotificationsEvent();
}