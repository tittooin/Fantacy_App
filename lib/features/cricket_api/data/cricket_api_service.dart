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
           headers: {
             'X-RapidAPI-Key': ApiKeys.rapidApiKey, // Pass Key for Fallback
             'X-RapidAPI-Host': ApiKeys.rapidApiHost,
           }
        )
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['matches'] is List) {
           final matches = (data['matches'] as List)
              .map((m) => CricketMatchModel.fromMap(m))
              .toList();
           debugPrint("Proxy Scraper: Fetched ${matches.length} matches");
           return matches;
        }
      }
    } catch (e) {
      debugPrint("Local Proxy Fetch Error: $e. Is the scraper running?");
    }

    // 2. Try RapidAPI Directly if Key is available (Might fail on Web due to CORS)
    debugPrint("Checking API Key for RapidAPI fallback...");
    if (ApiKeys.rapidApiKey.isNotEmpty) {
       // ... [API Call Logic] ...
       // (Keeping extensive logging code here if Proxy fails)
       try {
         final response = await _dio.get(
           'https://${ApiKeys.rapidApiHost}/matches/list-upcoming', 
           options: Options(
              headers: {
                'X-RapidAPI-Key': ApiKeys.rapidApiKey,
                'X-RapidAPI-Host': ApiKeys.rapidApiHost,
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
                 final seriesName = series['seriesAdWrapper']?['seriesName'] ?? "T20 Series";
                 if (series['matches'] != null) {
                    final mList = series['matches'] as List;
                    for (var m in mList) {
                       final matchInfo = m['matchInfo'];
                       final team1 = matchInfo['team1'];
                       final team2 = matchInfo['team2'];
                       
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
                          startDate: (matchInfo['startDate'] as num).toInt(),
                          endDate: (matchInfo['startDate'] as num).toInt() + 14400000, 
                          venue: "${matchInfo['venueInfo']['ground']}, ${matchInfo['venueInfo']['city']}",
                          status: "Upcoming", 
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
}

final cricketApiServiceProvider = Provider<RapidApiCricketService>((ref) {
  return RapidApiCricketService(Dio());
});
