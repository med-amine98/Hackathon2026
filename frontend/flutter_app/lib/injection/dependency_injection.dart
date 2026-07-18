// lib/injection/dependency_injection.dart

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_insurance_advisor/data/datasources/local/storage_service.dart';
import 'package:ai_insurance_advisor/data/datasources/remote/api_client.dart';
import 'package:ai_insurance_advisor/data/repositories/auth_repository.dart';
import 'package:ai_insurance_advisor/data/repositories/chat_repository.dart';
import 'package:ai_insurance_advisor/data/repositories/product_repository.dart';
import 'package:ai_insurance_advisor/data/repositories/profile_repository.dart';
import 'package:ai_insurance_advisor/presentation/bloc/auth/auth_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/chat/chat_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/profile/profile_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/car_health/car_health_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/notifications/notifications_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/weather/weather_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/traffic/traffic_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/declaration/declaration_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/conseil/conseil_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/prevention/prevention_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/conseil_chat/conseil_chat_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/declaration_chat/declaration_chat_bloc.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  getIt.registerSingleton<StorageService>(StorageService(prefs));
  getIt.registerSingleton<ApiClient>(ApiClient(prefs: prefs));

  getIt.registerSingleton<AuthRepository>(
    AuthRepository(getIt.get<StorageService>(), getIt.get<ApiClient>()),
  );
  getIt.registerSingleton<ChatRepository>(
    ChatRepository(getIt.get<ApiClient>()),
  );
  getIt.registerSingleton<ProductRepository>(
    ProductRepository(getIt.get<ApiClient>()),
  );
  getIt.registerSingleton<ProfileRepository>(
    ProfileRepository(getIt.get<ApiClient>()),
  );

  // ── BLoCs ─────────────────────────────────────────────────────────────────
  // AuthBloc est un singleton : le router (voir app/routes.dart) a besoin
  // d'écouter la même instance que celle fournie à l'app via BlocProvider,
  // sinon les redirections ne réagissent pas aux changements d'état.
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(getIt.get<AuthRepository>()),
  );
  getIt.registerFactory<ChatBloc>(
    () => ChatBloc(chatRepository: getIt.get<ChatRepository>()),
  );
  getIt.registerFactory<ProfileBloc>(
    () => ProfileBloc(getIt.get<ProfileRepository>()),
  );
  getIt.registerFactory<CarHealthBloc>(
    () => CarHealthBloc(),
  );
  getIt.registerFactory<NotificationsBloc>(
    () => NotificationsBloc(),
  );
  getIt.registerFactory<WeatherBloc>(
    () => WeatherBloc(),
  );
  getIt.registerFactory<TrafficBloc>(
    () => TrafficBloc(),
  );
  
  getIt.registerFactory<DeclarationBloc>(
    () => DeclarationBloc(),
  );
  getIt.registerFactory<ConseilBloc>(
    () => ConseilBloc(),
  );
  getIt.registerFactory<PreventionBloc>(
    () => PreventionBloc(
      authRepository: getIt.get<AuthRepository>(),
      profileRepository: getIt.get<ProfileRepository>(),
    ),
  );

  getIt.registerFactory<ConseilChatBloc>(
    () => ConseilChatBloc(),
  );
  getIt.registerFactory<DeclarationChatBloc>(
    () => DeclarationChatBloc(),
  );
}