import re

# Read the file
with open('g:/Fantacy_App/lib/features/contest/presentation/match_detail_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find and replace the function (lines 181-204)
new_function_lines = [
    '  Future<List<ContestModel>> _fetchContests() async {\n',
    '    try {\n',
    '      debugPrint("Fetching contests for matchId: ${widget.matchId} (D1-Only)");\n',
    '      \n',
    '      // Use D1 API instead of Firestore\n',
    '      final response = await ref.read(fantasyApiClientProvider).getContests(widget.matchId);\n',
    '      \n',
    '      if (response[\'success\'] == true && response[\'contests\'] != null) {\n',
    '        final contestsList = (response[\'contests\'] as List)\n',
    '            .map((json) => ContestModel.fromJson(json as Map<String, dynamic>))\n',
    '            .toList();\n',
    '        \n',
    '        debugPrint("Found ${contestsList.length} contests from D1");\n',
    '        return contestsList;\n',
    '      } else {\n',
    '        debugPrint("Failed to fetch contests: ${response[\'error\']}");\n',
    '        return [];\n',
    '      }\n',
    '    } catch (e) {\n',
    '      debugPrint("Error fetching contests: $e");\n',
    '      return [];\n',
    '    }\n',
    '  }\n',
]

# Replace lines 180-203 (0-indexed: 180-203)
new_lines = lines[:180] + new_function_lines + lines[204:]

# Write back
with open('g:/Fantacy_App/lib/features/contest/presentation/match_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("Function replaced successfully!")
