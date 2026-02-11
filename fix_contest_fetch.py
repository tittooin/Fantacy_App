import sys

# Read the entire file
with open('g:/Fantacy_App/lib/features/contest/presentation/match_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Old Firestore-based function
old_code = '''    try {
      // Convert String matchId to int for Firestore query
      final int matchIdInt = int.parse(widget.matchId);
      debugPrint("🔍 Fetching contests for matchId: $matchIdInt (converted from String '${widget.matchId}')");
      
      final snapshot = await FirebaseFirestore.instance
          .collection('contests')
          .where('matchId', isEqualTo: matchIdInt)
          .get();
      
      debugPrint("🔍 Found ${snapshot.docs.length} contests");
      
      final contests = snapshot.docs.map((doc) {
        debugPrint("🔍 Contest doc: ${doc.id}, data: ${doc.data()}");
        return ContestModel.fromJson(doc.data());
      }).toList();
      
      return contests;
    } catch (e) {
      debugPrint("❌ Error fetching contests: $e");
      return [];
    }'''

# New D1-based function
new_code = '''    try {
      debugPrint("Fetching contests for matchId: ${widget.matchId} (D1-Only)");
      
      // Use D1 API instead of Firestore
      final response = await ref.read(fantasyApiClientProvider).getContests(widget.matchId);
      
      if (response['success'] == true && response['contests'] != null) {
        final contestsList = (response['contests'] as List)
            .map((json) => ContestModel.fromJson(json as Map<String, dynamic>))
            .toList();
        
        debugPrint("Found ${contestsList.length} contests from D1");
        return contestsList;
      } else {
        debugPrint("Failed to fetch contests: ${response['error']}");
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching contests: $e");
      return [];
    }'''

# Replace
if old_code in content:
    content = content.replace(old_code, new_code)
    print("SUCCESS: Function replaced")
else:
    print("ERROR: Old code not found in file")
    sys.exit(1)

# Write back
with open('g:/Fantacy_App/lib/features/contest/presentation/match_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("File updated successfully!")
