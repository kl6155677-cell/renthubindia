import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/fcm_service.dart';
import '../../data/services/local_cache_service.dart';
import '../../data/models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../chat/chat_bloc.dart';
import '../chat/chat_event.dart';
import '../location/location_bloc.dart';
import '../location/location_event.dart';
import '../../core/utils/error_utils.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final LocationBloc locationBloc;
  final ChatBloc chatBloc;

  AuthBloc({
    required this.authRepository,
    required this.locationBloc,
    required this.chatBloc,
  }) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<FirebaseLoginRequested>(_onFirebaseLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.getCachedUser();
      if (user != null) {
        try {
          final profile = await authRepository.getUserProfile();
          emit(AuthAuthenticated(profile));
        } catch (_) {
          await authRepository.logout();
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.login(event.email, event.password);
      emit(AuthAuthenticated(user));
      
      // Auto-trigger services
      locationBloc.add(const DetectLocation());
      FCMService.registerToken();
      chatBloc.add(ConnectSocket());
    } catch (e) {
      emit(AuthError(ErrorUtils.formatError(e)));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onFirebaseLoginRequested(FirebaseLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.firebaseLogin(event.idToken);
      emit(AuthAuthenticated(user));
      
      // Auto-trigger services
      locationBloc.add(const DetectLocation());
      FCMService.registerToken();
      chatBloc.add(ConnectSocket());
    } catch (e) {
      emit(AuthError(ErrorUtils.formatError(e)));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onRegisterRequested(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.register(
        event.name,
        event.email,
        event.password,
        phone: event.phone,
      );
      
      // We don't want to log in directly. 
      // The register repository currently saves tokens, so we MUST logout to clear them.
      await authRepository.logout();
      
      emit(AuthRegistrationSuccess());
    } catch (e) {
      emit(AuthError(ErrorUtils.formatError(e)));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.logout();
      await LocalCacheService.clearAll();
      chatBloc.add(DisconnectSocket());
      emit(AuthUnauthenticated());
    } catch (e) {
      await LocalCacheService.clearAll();
      chatBloc.add(DisconnectSocket());
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onUpdateProfileRequested(UpdateProfileRequested event, Emitter<AuthState> emit) async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      emit(AuthLoading());
      try {
        UserModel user = currentState.user;
        if (event.avatarPath != null) {
          user = await authRepository.uploadAvatar(event.avatarPath!);
        }
        final updatedUser = await authRepository.updateProfile({
          'name': event.name,
          'phone': event.phone,
          'city': event.city,
          'country': event.country,
          'currency': event.currency,
          'avatarUrl': user.avatarUrl,
        });
        emit(AuthAuthenticated(updatedUser));
      } catch (e) {
        emit(AuthError(ErrorUtils.formatError(e)));
        emit(AuthAuthenticated(currentState.user));
      }
    }
  }
}
