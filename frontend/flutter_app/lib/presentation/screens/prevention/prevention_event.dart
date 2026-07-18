// lib/presentation/bloc/prevention/prevention_event.dart

part of 'prevention_bloc.dart';

abstract class PreventionEvent {
  const PreventionEvent();
}

class LoadPreventionDataEvent extends PreventionEvent {
  const LoadPreventionDataEvent();
}

class RefreshPreventionEvent extends PreventionEvent {
  const RefreshPreventionEvent();
}