import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/network/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/supabase_auth_data_source.dart';
import 'data/datasources/supabase_comment_data_source.dart';
import 'data/datasources/supabase_notification_data_source.dart';
import 'data/datasources/supabase_ticket_data_source.dart';
import 'data/datasources/supabase_storage_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/comment_repository_impl.dart';
import 'data/repositories/notification_repository_impl.dart';
import 'data/repositories/ticket_repository_impl.dart';
import 'domain/usecases/auth/auth_usecases.dart';
import 'domain/usecases/comments/comment_usecases.dart';
import 'domain/usecases/notifications/notification_usecases.dart';
import 'domain/usecases/tickets/ticket_usecases.dart';
import 'presentation/providers/providers.dart';
import 'presentation/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const ETicketingApp());
}

class ETicketingApp extends StatefulWidget {
  const ETicketingApp({super.key});

  @override
  State<ETicketingApp> createState() => _ETicketingAppState();
}

class _ETicketingAppState extends State<ETicketingApp> {
  bool _isDarkMode = false;
  late final SupabaseClient _supabase;
  late final AuthProvider _authProvider;
  late final TicketProvider _ticketProvider;
  late final NotificationProvider _notificationProvider;
  late final SupabaseStorageDataSource _storageDataSource;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;

    final authDataSource = SupabaseAuthDataSource(_supabase);
    final ticketDataSource = SupabaseTicketDataSource(_supabase);
    final commentDataSource = SupabaseCommentDataSource(_supabase);
    final notificationDataSource = SupabaseNotificationDataSource(_supabase);
    final storageDataSource = SupabaseStorageDataSource(_supabase);

    final authRepo = AuthRepositoryImpl(authDataSource);
    final notificationRepo = NotificationRepositoryImpl(notificationDataSource);
    final ticketRepo = TicketRepositoryImpl(ticketDataSource, commentDataSource);
    final commentRepo = CommentRepositoryImpl(commentDataSource);

    _authProvider = AuthProvider(
      loginUseCase: LoginUseCase(authRepo),
      registerUseCase: RegisterUseCase(authRepo),
      logoutUseCase: LogoutUseCase(authRepo),
      getCurrentUserUseCase: GetCurrentUserUseCase(authRepo),
      updateProfileUseCase: UpdateProfileUseCase(authRepo),
      resetPasswordUseCase: ResetPasswordUseCase(authRepo),
    );

    _ticketProvider = TicketProvider(
      getTicketsUseCase: GetTicketsUseCase(ticketRepo),
      getTicketByIdUseCase: GetTicketByIdUseCase(ticketRepo),
      createTicketUseCase: CreateTicketUseCase(ticketRepo),
      updateTicketStatusUseCase: UpdateTicketStatusUseCase(ticketRepo),
      assignTicketUseCase: AssignTicketUseCase(ticketRepo),
      getStatisticsUseCase: GetStatisticsUseCase(ticketRepo),
      getHelpdeskUsersUseCase: GetHelpdeskUsersUseCase(ticketRepo),
      addCommentUseCase: AddCommentUseCase(commentRepo),
      getCommentsUseCase: GetCommentsUseCase(commentRepo),
    );

    _notificationProvider = NotificationProvider(
      getNotificationsUseCase: GetNotificationsUseCase(notificationRepo),
      getUnreadCountUseCase: GetUnreadCountUseCase(notificationRepo),
      markAsReadUseCase: MarkAsReadUseCase(notificationRepo),
      markAllAsReadUseCase: MarkAllAsReadUseCase(notificationRepo),
    );

    _storageDataSource = storageDataSource;
  }

  void _toggleTheme() => setState(() => _isDarkMode = !_isDarkMode);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _ticketProvider),
        ChangeNotifierProvider.value(value: _notificationProvider),
        Provider.value(value: _storageDataSource),
      ],
      child: MaterialApp(
        title: 'E-Ticketing Helpdesk',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const SplashScreen(),
        builder: (context, child) {
          return ThemeToggleProvider(
            toggleTheme: _toggleTheme,
            isDarkMode: _isDarkMode,
            child: child!,
          );
        },
      ),
    );
  }
}

class ThemeToggleProvider extends InheritedWidget {
  const ThemeToggleProvider({
    required this.toggleTheme,
    required this.isDarkMode,
    required super.child,
  });

  final VoidCallback toggleTheme;
  final bool isDarkMode;

  static ThemeToggleProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeToggleProvider>();
  }

  @override
  bool updateShouldNotify(ThemeToggleProvider old) =>
      isDarkMode != old.isDarkMode;
}
