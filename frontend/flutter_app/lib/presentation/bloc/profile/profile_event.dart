// lib/presentation/bloc/profile/profile_event.dart

part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadProfileEvent extends ProfileEvent {
  const LoadProfileEvent();
}

class UpdateProfileEvent extends ProfileEvent {
  final Map<String, dynamic> profileData;
  
  const UpdateProfileEvent(this.profileData);
  
  @override
  List<Object?> get props => [profileData];
}