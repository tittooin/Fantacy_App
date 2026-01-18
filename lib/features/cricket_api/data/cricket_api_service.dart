import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axevora11/features/cricket_api/domain/cricket_match_model.dart';
import 'package:flutter/foundation.dart';
import 'package:axevora11/core/constants/api_keys.dart';

// Interface
abstract class CricketApiService {
  Future<List<CricketMatchModel>> fetchUpcomingMatches();
}



// Implementation
class RapidApiCricketService implements CricketApiService {
  final Dio _dio;
  
  RapidApiCricketService(this._dio);
  
  // Toggle this to use Local Proxy (True) or Mock Data (False fallback)
  static const bool useLocalProxy = true;
  
  // Use localhost for Android Emulator (10.0.2.2) or Web (localhost)
  // For simplicity assuming Web/Desktop here.
  static const String _localUrl = 'http://localhost:3000'; 

  @override
  Future<List<CricketMatchModel>> fetchUpcomingMatches() async {
    // 1. Try Local Proxy (Node Scraper) - Best for Web to avoid CORS
    // Run 'node index.js' in scraper folder
    try {
      debugPrint("Fetching from Local Proxy: $_localUrl/matches");
      final response = await _dio.get(
        '$_localUrl/matches',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        )
      );
      
      if (response.statusCode == 200) {
        debugPrint("Local Scraper Success");
        // Assuming _parseMatches is similar to _parseRapidApiMatches or fromMap
        // For now, using the existing _parseRapidApiMatches if the scraper returns RapidAPI-like structure
        // Or, if scraper returns a direct list of maps, use CricketMatchModel.fromMap
        final data = response.data;
        if (data is Map<String, dynamic> && data['matches'] is List) {
           final matches = (data['matches'] as List)
              .map((m) => CricketMatchModel.fromMap(m))
              .toList();
           debugPrint("Proxy Scraper: Fetched ${matches.length} matches");
           if (matches.isNotEmpty) return matches;
        } else if (data is Map<String, dynamic> && data['typeMatches'] != null) {
           // If scraper returns data in RapidAPI format
           final matches = _parseRapidApiMatches(data);
           if (matches.isNotEmpty) return matches;
        }
      }
    } catch (e) {
      debugPrint("Local Scraper failed/unreachable: $e. Is the scraper running?");
    }

    // 2. Try Cloudflare Pages Function (For Production Web)
    // This avoids CORS by calling the server-side function /api/matches
    try {
      debugPrint("Attempting to fetch from Cloudflare Function: /api/matches");
      // Use relative path which works on Web to hit same-origin
      final response = await _dio.get('/api/matches');
      
      if (response.statusCode == 200) {
        debugPrint("Cloudflare Function Success");
        return _parseRapidApiMatches(response.data);
      }
    } catch (e) {
      debugPrint("Cloudflare Function failed (Local/Dev?): $e");
    }

    // 3. Try RapidAPI Directly if Key is available (Might fail on Web due to CORS)
    debugPrint("Checking API Key for RapidAPI fallback...");
    if (ApiKeys.rapidApiKey.isNotEmpty) {
       // ... [API Call Logic] ...
       // (Keeping extensive logging code here if Proxy fails)
       try {
         final response = await _dio.get(
           'https://cricbuzz-cricket2.p.rapidapi.com/matches/v1/upcoming',
           options: Options(
              headers: {
                'X-RapidAPI-Key': ApiKeys.rapidApiKey,
                'X-RapidAPI-Host': 'cricbuzz-cricket2.p.rapidapi.com',
              },
              validateStatus: (status) => true,
           )
         );
         if (response.statusCode == 200) {
            final data = response.data;
            if (data['typeMatches'] != null) {
               return _parseRapidApiMatches(data);
            }
         }
       } catch (e) {
          debugPrint("RapidAPI Fallback Error: $e");
       }
    }

    // 3. No Fallback to Mock Data (Clean for Production)
    debugPrint("No API data found. Returning empty list.");
    return [];
  }

  List<CricketMatchModel> _parseRapidApiMatches(Map<String, dynamic> data) {
      List<CricketMatchModel> matches = [];
      try {
        final types = data['typeMatches'] as List;
        for (var type in types) {
           if (type['seriesMatches'] != null) {
              final seriesList = type['seriesMatches'] as List;
              for (var series in seriesList) {
                  // Check for seriesAdWrapper structure (Common in v1/upcoming)
                  var seriesData = series;
                  if (series['seriesAdWrapper'] != null) {
                    seriesData = series['seriesAdWrapper'];
                  }
                  
                  final seriesName = seriesData['seriesName'] ?? "T20 Series";
                  
                  if (seriesData['matches'] != null) {
                     final mList = seriesData['matches'] as List;
                     for (var m in mList) {
                        final matchInfo = m['matchInfo'];
                        final team1 = matchInfo['team1'];
                        final team2 = matchInfo['team2'];
                        
                        // Parse Date safely
                        int startDt = 0;
                        int endDt = 0;
                        try {
                           startDt = int.parse(matchInfo['startDate'].toString());
                           endDt = int.parse(matchInfo['endDate'].toString());
                        } catch (e) {
                           startDt = DateTime.now().millisecondsSinceEpoch;
                        }

                        matches.add(CricketMatchModel(
                           id: matchInfo['matchId'],
                           seriesName: seriesName,
                           matchDesc: matchInfo['matchDesc'] ?? "Match",
                           matchFormat: matchInfo['matchFormat'] ?? "T20",
                           team1Name: team1['teamName'],
                           team1ShortName: team1['teamSName'],
                           team1Img: team1['imageId']?.toString() ?? "1",
                           team2Name: team2['teamName'],
                           team2ShortName: team2['teamSName'],
                           team2Img: team2['imageId']?.toString() ?? "1",
                           startDate: startDt,
                           endDate: endDt, 
                           venue: "${matchInfo['venueInfo']['ground']}, ${matchInfo['venueInfo']['city']}",
                           status: "Upcoming",
                           seriesId: matchInfo['seriesId'] ?? 0,
                           team1Id: team1['teamId'] ?? 0,
                           team2Id: team2['teamId'] ?? 0,
                        ));
                     }
                  }
              }
           }
        }
      } catch (e) {
         debugPrint("Parsing Error: $e");
      }
      return matches;
  }

  // Fetch Scorecard needed for Live Scoring
  Future<Map<String, dynamic>> fetchScorecard(String matchId) async {
    const bool forceMock = false; 
    
    // 1. Try Local Proxy Tunnel (Web CORS Fix)
    // Routes to localhost:3000/scorecard/:id which then calls RapidAPI
    if (!forceMock && ApiKeys.rapidApiKey.isNotEmpty) {
      try {
        debugPrint("Fetching Scorecard via Proxy: $_localUrl/scorecard/$matchId");
        final response = await _dio.get(
          '$_localUrl/scorecard/$matchId', 
           options: Options(
              headers: {
                'X-RapidAPI-Key': ApiKeys.rapidApiKey,
                'X-RapidAPI-Host': ApiKeys.rapidApiHost,
              },
              validateStatus: (status) => true,
           )
        );
        
        if (response.statusCode == 200) {
           return response.data as Map<String, dynamic>;
        } else {
           debugPrint("Proxy Scorecard Error: ${response.statusCode} - ${response.data}");
        }
      } catch (e) {
        debugPrint("Proxy Scorecard Exception: $e. Is Scraper 'node index.js' running?");
      }
    }

    // 2. Fallback Mock Scorecard
    debugPrint("Falling back to Mock Scorecard for ID $matchId");
    return {
      'scoreCard': [
        // ... (Keep existing Mock Data structure)
        {
          'batTeamDetails': {
            'batsmenData': {
              'bat_1': {'runs': 45, 'balls': 30, 'fours': 4, 'sixes': 2, 'isOut': false},
              'bat_2': {'runs': 12, 'balls': 10, 'fours': 1, 'sixes': 0, 'isOut': true, 'outDesc': 'b Bumrah'},
            }
          },
          'bowlTeamDetails': {
             'bowlersData': {
                'bowl_1': {'wickets': 1, 'overs': 3, 'runs': 24}
             }
          }
        }
      ]
    };
  }

  // ... (Keep _getMockMatches)
  List<CricketMatchModel> _getMockMatches() {
     // ...
    return [
      const CricketMatchModel(
        id: 89571, // UPDATED: Real ID for API Testing
        seriesName: "IPL 2026 (Mock)",
        matchDesc: "1st Match, Group A",
        matchFormat: "T20",
        team1Name: "Chennai Super Kings",
        team1ShortName: "CSK",
        team1Img: "5800", 
        team2Name: "Mumbai Indians",
        team2ShortName: "MI",
        team2Img: "5801",
        startDate: 1768462200000,
        endDate: 1768491000000,
        venue: "Wankhede Stadium, Mumbai",
        status: "Upcoming",
      ),
    ];
  }


  Future<Map<String, dynamic>> fetchSquads(int matchId, int seriesId, int t1Id, int t2Id, String t1Short, String t2Short) async {
     // Uses the generic /proxy route in scraper to hit any RapidAPI endpoint
    try {
      debugPrint("Fetching Squads for $matchId via Function...");
      // Use Cloudflare Function /api/squads
      final response = await _dio.get(
        '/api/squads',
        queryParameters: {
          'id': matchId,
          'seriesId': seriesId,
          't1Id': t1Id,
          't2Id': t2Id
        },
      );

      final data = response.data;
      List<Map<String, dynamic>> parsedPlayers = [];
      bool isXI = false;

      // Check Source
      if (data['source'] == 'playing_xi') {
          isXI = true;
      }
      
      // Helper function to process player list
      void processPlayerList(List<dynamic>? players, String teamShort) {
         if (players == null) return;
         for (var p in players) {
             // Skip header entries
             if (p['isHeader'] == true) continue;

             String role = 'BAT';
             String apiRole = p['role']?.toString().toLowerCase() ?? '';
             if (apiRole.contains('keeper')) role = 'WK';
             else if (apiRole.contains('all')) role = 'AR';
             else if (apiRole.contains('bowl')) role = 'BOWL';
             
             parsedPlayers.add({
               'id': p['id'].toString(),
               'name': p['name'] ?? 'Unknown',
               'teamShortName': teamShort,
               'role': role,
               'credits': 8.5,
               // Fallback: Use imageId if faceImageId is missing
               'imageUrl': (p['faceImageId'] ?? p['imageId'])?.toString() ?? '',
               'points': 0.0
             });
         }
      }

      // Check for Falback Structure (Series Squads)
      if (data['isFallback'] == true) {
          processPlayerList(data['team1'], t1Short);
          processPlayerList(data['team2'], t2Short);
      } 
      // Check for Standard Structure (scov2)
      else if (data['matchInfo'] != null) {
          final mInfo = data['matchInfo'];
          // scov2 structure usually has team1 -> playerDetails
          // But sometimes it might be team1 -> squad? verify if needed. 
          // Assuming test_squad_data.js structure: team1.playerDetails
          if (mInfo['team1'] != null) {
             processPlayerList(mInfo['team1']['playerDetails'], t1Short);
          }
          if (mInfo['team2'] != null) {
             processPlayerList(mInfo['team2']['playerDetails'], t2Short);
          }
      }
        
      debugPrint("API: Fetched & Parsed ${parsedPlayers.length} players. isXI: $isXI");
      return {
        'players': parsedPlayers,
        'isXI': isXI
      };

    } catch (e) {
      debugPrint("Squad Fetch Error: $e");
    }
    return {'players': [], 'isXI': false};
  }
}

final cricketApiServiceProvider = Provider<RapidApiCricketService>((ref) {
  return RapidApiCricketService(Dio());
});
