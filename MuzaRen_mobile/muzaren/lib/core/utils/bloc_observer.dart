import 'package:flutter_bloc/flutter_bloc.dart';
import 'logger.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    AppLogger.bloc(bloc.runtimeType.toString(), '➡️ Event: $event');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    // Silent for high velocity changes like scrolls or search inputs if needed
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    AppLogger.bloc(
      bloc.runtimeType.toString(),
      '🔄 Transition: ${transition.currentState.runtimeType} -> ${transition.nextState.runtimeType}',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    AppLogger.error('❌ Bloc Error in ${bloc.runtimeType}', error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
