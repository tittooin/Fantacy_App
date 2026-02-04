import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';

/// One-time script to fix missing team short names in existing matches
Future<void> fixTeamShortNames() async {
  final firestore = FirebaseFirestore.instance;
  
  print('🔧 Starting team short names fix...');
  
  try {
    // Get all matches
    final matchesSnapshot = await firestore.collection('matches').get();
    
    print('📊 Found ${matchesSnapshot.docs.length} matches');
    
    int updated = 0;
    int skipped = 0;
    
    for (var doc in matchesSnapshot.docs) {
      final data = doc.data();
      final matchId = doc.id;
      
      // Check if team short names are missing or empty
      final team1Short = data['team1ShortName'] as String?;
      final team2Short = data['team2ShortName'] as String?;
      
      if (team1Short == null || team1Short.isEmpty || team2Short == null || team2Short.isEmpty) {
        // Load match using fromMap (which will auto-generate short names)
        final match = CricketMatchModel.fromMap(data);
        
        // Update Firestore with generated short names
        await firestore.collection('matches').doc(matchId).update({
          'team1ShortName': match.team1ShortName,
          'team2ShortName': match.team2ShortName,
        });
        
        print('✅ Updated match $matchId: ${match.team1Name} (${match.team1ShortName}) vs ${match.team2Name} (${match.team2ShortName})');
        updated++;
      } else {
        print('⏭️  Skipped match $matchId (already has short names)');
        skipped++;
      }
    }
    
    print('\n🎉 Fix complete!');
    print('   Updated: $updated matches');
    print('   Skipped: $skipped matches');
    
  } catch (e) {
    print('❌ Error: $e');
    rethrow;
  }
}
