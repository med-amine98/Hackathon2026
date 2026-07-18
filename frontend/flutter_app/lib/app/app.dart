// lib/app/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_insurance_advisor/app/routes.dart';
import 'package:ai_insurance_advisor/app/theme.dart';
import 'package:ai_insurance_advisor/injection/dependency_injection.dart';
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
import 'package:ai_insurance_advisor/presentation/bloc/agent_chat/agent_chat_bloc.dart';
import 'package:ai_insurance_advisor/presentation/widgets/agent_chat_bubble.dart';

class AIInsuranceApp extends StatelessWidget {
  const AIInsuranceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // ─── Auth ──────────────────────────────────────────────────────────
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()..add(const AuthCheckRequestedEvent()),
        ),
        
        // ─── Chat ──────────────────────────────────────────────────────────
        BlocProvider<ChatBloc>(
          create: (context) => getIt<ChatBloc>(),
        ),
        
        // ─── Profile ──────────────────────────────────────────────────────
        BlocProvider<ProfileBloc>(
          create: (context) => getIt<ProfileBloc>(),
        ),
        
        // ─── Car Health ──────────────────────────────────────────────────
        BlocProvider<CarHealthBloc>(
          create: (context) => getIt<CarHealthBloc>(),
        ),
        
        // ─── Notifications ──────────────────────────────────────────────
        BlocProvider<NotificationsBloc>(
          create: (context) => getIt<NotificationsBloc>(),
        ),
        
        // ─── Weather ─────────────────────────────────────────────────────
        BlocProvider<WeatherBloc>(
          create: (context) => getIt<WeatherBloc>(),
        ),
        
        // ─── Traffic ─────────────────────────────────────────────────────
        BlocProvider<TrafficBloc>(
          create: (context) => getIt<TrafficBloc>(),
        ),
        
        // ─── Declaration ────────────────────────────────────────────────
        BlocProvider<DeclarationBloc>(
          create: (context) => getIt<DeclarationBloc>(),
        ),
        
        // ─── Conseil ─────────────────────────────────────────────────────
        BlocProvider<ConseilBloc>(
          create: (context) => getIt<ConseilBloc>(),
        ),
        
        // ─── Prevention ─────────────────────────────────────────────────
        BlocProvider<PreventionBloc>(
          create: (context) => getIt<PreventionBloc>(),
        ),
        
        // ─── Conseil Chat ────────────────────────────────────────────────
        BlocProvider<ConseilChatBloc>(
          create: (context) => getIt<ConseilChatBloc>(),
        ),
        
        // ─── Declaration Chat ────────────────────────────────────────────
        BlocProvider<DeclarationChatBloc>(
          create: (context) => getIt<DeclarationChatBloc>(),
        ),

        // ─── Agent Chat (floating bubble, linked to the agent) ────────────
        BlocProvider<AgentChatBloc>(
          create: (context) => getIt<AgentChatBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'AssurIA - Assistant IA',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
        // Overlays the floating agent chat bubble above whatever screen
        // go_router is currently showing, app-wide — MaterialApp.router has
        // no persistent Scaffold of its own to attach a FAB to, so this is
        // the one place a truly global floating widget can be mounted.
        builder: (context, child) {
          return Stack(
            children: [
              if (child != null) child,
              const AgentChatBubble(),
            ],
          );
        },
      ),
    );
  }
}