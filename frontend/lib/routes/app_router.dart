import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/game_screen.dart';
import '../screens/result_screen.dart';

class AppRouter {
  static GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/game',
        builder: (context, state) => const GameScreen(),
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) => const ResultScreen(),
      ),
    ],
  );
}
