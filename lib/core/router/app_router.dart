
import 'package:axevora11/features/auth/presentation/login_screen.dart';
import 'package:axevora11/features/auth/presentation/splash_screen.dart';
import 'package:axevora11/features/location/data/location_service.dart';
import 'package:axevora11/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:axevora11/features/admin/presentation/admin_scaffold.dart';
import 'package:axevora11/features/cricket_api/presentation/contest_creator_screen.dart';
import 'package:axevora11/features/admin/presentation/match_control_screen.dart';
import 'package:axevora11/features/admin/presentation/league_management_screen.dart'; // Added
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:axevora11/features/cricket_api/presentation/match_import_screen.dart';
import 'package:axevora11/features/cricket_api/domain/contest_model.dart';
import 'package:axevora11/features/location/presentation/state_selection_screen.dart';
import 'package:axevora11/features/auth/data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Placeholder imports for screens
import 'package:axevora11/features/home/presentation/home_screen.dart';
import 'package:axevora11/features/contest/presentation/match_detail_screen.dart';
import 'package:axevora11/features/contest/presentation/contest_detail_screen.dart';
import 'package:axevora11/features/team/presentation/team_builder_screen.dart';
import 'package:axevora11/features/team/presentation/team_preview_screen.dart';
import 'package:axevora11/features/team/presentation/captain_selection_screen.dart';
import 'package:axevora11/features/team/domain/player_model.dart';
import 'package:axevora11/features/wallet/presentation/wallet_screen.dart';
import 'package:axevora11/features/user/presentation/profile_screen.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title)), body: Center(child: Text(title)));
}

// Wrapper to convert Stream<User?> to a Listenable ValueNotifier
class UserValueNotifier extends ValueNotifier<User?> {
  UserValueNotifier(Stream<User?> stream) : super(FirebaseAuth.instance.currentUser) { // Initialize with current user
    stream.listen((user) {
      value = user;
    });
  }
}

final authState = Provider<UserValueNotifier>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return UserValueNotifier(authRepo.authStateChanges);
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authState);
  
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: authNotifier, 
    redirect: (context, state) {
      final user = authNotifier.value; 
      final String path = state.uri.toString();
      final bool isLocationSet = ref.read(locationServiceProvider).hasSelectedState;

      debugPrint("Router Debug: Path=$path | User=${user?.uid}");

      // C. Admin Access Check (Moved top for Dev Verification)
      if (path.startsWith('/admin')) {
         debugPrint("Router: Allowing Admin Access to $path");
         // Force allow - return null tells GoRouter to display the intended route
         return null; 
      }

      // 1. Guest User: Allow only Login and Splash
      if (user == null) {
        if (path == '/login' || path == '/') return null; 
        return '/login';
      }

      // 2. Logged In User
      
      // A. Location NOT Verified
      if (!isLocationSet) {
        // Allow Splash to finish its job (it will navigate to /home later)
        if (path == '/') return null;
        
        // If already on verify screen, stay there
        if (path == '/location-verify') return null;
        
        // Otherwise, force verify
        debugPrint("Router: Force Redirect -> /location-verify");
        return '/location-verify';
      }

      // B. Location Verified
      // C. Admin Access Check
      // If user is trying to access admin, allow him (later add role check)
      if (path.startsWith('/admin')) {
         return null; 
      }

      // If on Login, Splash, or Verify screen -> Go Home
      if (path == '/login' || path == '/' || path == '/location-verify') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/profile/:uid',
        builder: (context, state) {
           final uid = state.pathParameters['uid']!;
           return ProfileScreen(userId: uid);
        },
      ),
      GoRoute(
        path: '/location-verify',
        builder: (context, state) => const StateSelectionScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        name: 'match_detail',
        path: '/match/:matchId',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          
          CricketMatchModel? match;
          final extra = state.extra;
          if (extra is CricketMatchModel) {
            match = extra;
          } else if (extra is Map<String, dynamic>) {
            match = CricketMatchModel.fromMap(extra);
          }
          
          return MatchDetailScreen(matchId: matchId, match: match);
        },
      ),
      GoRoute(
        path: '/contest/:contestId',
        builder: (context, state) {
          final contestId = state.pathParameters['contestId']!;
          final extras = state.extra as Map<String, dynamic>?; // Nullable Map

          // Safely parse ContestModel
          ContestModel? contest;
          if (extras != null && extras['contest'] != null) {
             if (extras['contest'] is ContestModel) {
                contest = extras['contest'] as ContestModel;
             } else if (extras['contest'] is Map<String, dynamic>) {
                contest = ContestModel.fromJson(extras['contest'] as Map<String, dynamic>);
             }
          }

          // Safely parse CricketMatchModel
          CricketMatchModel? match;
          if (extras != null && extras['match'] != null) {
              if (extras['match'] is CricketMatchModel) {
                 match = extras['match'] as CricketMatchModel;
              } else if (extras['match'] is Map<String, dynamic>) {
                 match = CricketMatchModel.fromMap(extras['match'] as Map<String, dynamic>);
              }
          }
          
          final matchId = extras?['matchId'] as String?;

          return ContestDetailScreen(contestId: contestId, contest: contest, match: match, matchId: matchId);
        },
      ),
      GoRoute(
        path: '/match/:matchId/create-team',
        builder: (context, state) {
          // Check if extra is Model or Map
          final extra = state.extra;
          CricketMatchModel match;
          List<PlayerModel>? initialPlayers;

          if (extra is CricketMatchModel) {
             match = extra;
          } else if (extra is Map<String, dynamic>) {
             match = extra['match'] as CricketMatchModel;
             initialPlayers = extra['initialPlayers'] as List<PlayerModel>?;
          } else {
             // If navigating directly via URL (not supported without ID fetch yet), or error
             // Ideally we fetch match by matchId here. For now, assume passed.
             throw Exception("Match object required for TeamBuilder");
          }

          return TeamBuilderScreen(match: match, initialPlayers: initialPlayers);
        },
        routes: [
           GoRoute(
            path: 'preview',
            builder: (context, state) {
              final extras = state.extra as Map<String, dynamic>;
              return TeamPreviewScreen(
                selectedPlayers: extras['players'] as List<PlayerModel>,
                team1Name: extras['team1Name'] as String,
                team2Name: extras['team2Name'] as String,
                isEditMode: extras['isEditMode'] as bool? ?? false,
                matchId: state.pathParameters['matchId'],
                match: extras['match'] as CricketMatchModel?,
              );
            },
          ),
          GoRoute(
            path: 'captain',
            builder: (context, state) {
               final extras = state.extra as List<PlayerModel>;
               // We need matchId. Since it's nested under /match/:matchId, we can get it from path params
               final matchId = state.pathParameters['matchId']!;
               return CaptainSelectionScreen(selectedPlayers: extras, matchId: matchId);
            }
          ),
        ]
      ),
      
      // Admin Shell Route
      ShellRoute(
        builder: (context, state, child) {
          return AdminScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/matches',
            builder: (context, state) => const MatchImportScreen(),
          ),
          GoRoute(
            path: '/admin/contests',
            builder: (context, state) => const PlaceholderScreen(title: "Admin Contests"),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const PlaceholderScreen(title: "User Management"),
          ),
          GoRoute(
            path: '/admin/wallet',
            builder: (context, state) => const PlaceholderScreen(title: "Wallet Requests"),
          ),
          GoRoute(
            path: '/admin/matches/create-contest',
            builder: (context, state) {
              final match = state.extra;
              if (match is! CricketMatchModel) {
                 return const Center(child: Text("Error: No Match Selected. Please go back and select a match."));
              }
              return ContestCreatorScreen(match: match);
            },
          ),
          GoRoute(
            path: '/admin/match-control',
            builder: (context, state) => const MatchControlScreen(),
          ),
          GoRoute(
            path: '/admin/leagues',
            builder: (context, state) => const LeagueManagementScreen(),
          ),
        ],
      ),
    ],
  );
});
