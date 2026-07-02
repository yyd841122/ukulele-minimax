import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_page.dart';
import '../features/tuner/tuner_page.dart';
import '../features/metronome/metronome_page.dart';
import '../features/sheets/sheets_page.dart';
import '../features/sheets/sheet_detail_page.dart';
import '../features/course_center/course_list_page.dart';
import '../features/course_center/course_detail_page.dart';
import '../features/ai_coach/ai_coach_page.dart';
import 'constants.dart';
import 'theme.dart';

/// 全局路由配置
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (BuildContext context, GoRouterState state) =>
          const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.tuner,
      name: 'tuner',
      builder: (BuildContext context, GoRouterState state) =>
          const TunerPage(),
    ),
    GoRoute(
      path: AppRoutes.metronome,
      name: 'metronome',
      builder: (BuildContext context, GoRouterState state) =>
          const MetronomePage(),
    ),
    GoRoute(
      path: AppRoutes.sheets,
      name: 'sheets',
      builder: (BuildContext context, GoRouterState state) =>
          const SheetsPage(),
    ),
    GoRoute(
      path: AppRoutes.sheetDetail,
      name: 'sheetDetail',
      builder: (BuildContext context, GoRouterState state) {
        final String id = state.pathParameters['id'] ?? '0';
        return SheetDetailPage(sheetId: int.tryParse(id) ?? 0);
      },
    ),
    GoRoute(
      path: AppRoutes.courseCenter,
      name: 'courseCenter',
      builder: (BuildContext context, GoRouterState state) =>
          const CourseCenterPage(),
    ),
    GoRoute(
      path: '/courses/:id',
      name: 'courseCenterDetail',
      builder: (BuildContext context, GoRouterState state) =>
          CourseDetailPage(courseId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: AppRoutes.aiCoach,
      name: 'aiCoach',
      builder: (BuildContext context, GoRouterState state) =>
          const AiCoachPage(),
    ),
  ],
);

/// App 根组件
class UkuleleApp extends StatelessWidget {
  const UkuleleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider>[
        // 全局 Cubit 注入点（用户、设置等）
        BlocProvider<ServiceLocatorCubit>(
          create: (_) => ServiceLocatorCubit(),
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
        // 本地化：使用 flutter_localizations 的全局 delegate
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[
          Locale('zh', 'CN'),
          Locale('en', 'US'),
        ],
      ),
    );
  }
}

/// 占位 Cubit：用于全局服务注入（用户、设置、主题等）
/// 后续会扩展为真正的 GlobalCubit
class ServiceLocatorCubit extends Cubit<int> {
  ServiceLocatorCubit() : super(0);
}