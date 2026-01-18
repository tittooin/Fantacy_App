class CricketMatchModel {
  final int id;
  final String seriesName;
  final String matchDesc;
  final String matchFormat;
  final String team1Name;
  final String team1ShortName;
  final String team1Img;
  final String team2Name;
  final String team2ShortName;
  final String team2Img;
  final int startDate;
  final int endDate;
  final String venue;
  final String status; // 'Created', 'Upcoming', 'Live', 'Completed'
  final String lineupStatus; // 'Pending' or 'Confirmed'
  final List<String> playingXI;
  final String? leagueId; 
  final int seriesId;
  final int team1Id;
  final int team2Id;

  const CricketMatchModel({
    required this.id,
    required this.seriesName,
    required this.matchDesc,
    required this.matchFormat,
    required this.team1Name,
    required this.team1ShortName,
    required this.team1Img,
    required this.team2Name,
    required this.team2ShortName,
    required this.team2Img,
    required this.startDate,
    required this.endDate,
    required this.venue,
    required this.status,
    this.lineupStatus = 'Pending',
    this.playingXI = const [],
    this.leagueId,
    this.seriesId = 0,
    this.team1Id = 0,
    this.team2Id = 0,
  });

  factory CricketMatchModel.fromJson(Map<String, dynamic> json) {
    final matchInfo = json['matchInfo'] as Map<String, dynamic>? ?? {};
    final team1 = matchInfo['team1'] as Map<String, dynamic>? ?? {};
    final team2 = matchInfo['team2'] as Map<String, dynamic>? ?? {};
    final venueInfo = matchInfo['venueInfo'] as Map<String, dynamic>? ?? {};

    return CricketMatchModel(
      id: matchInfo['matchId'] as int? ?? 0,
      seriesName: matchInfo['seriesName'] as String? ?? '',
      matchDesc: matchInfo['matchDesc'] as String? ?? '',
      matchFormat: matchInfo['matchFormat'] as String? ?? '',
      team1Name: team1['teamName'] as String? ?? '',
      team1ShortName: team1['teamSName'] as String? ?? '',
      team1Img: team1['imageId']?.toString() ?? '',
      team2Name: team2['teamName'] as String? ?? '',
      team2ShortName: team2['teamSName'] as String? ?? '',
      team2Img: team2['imageId']?.toString() ?? '',
      startDate: int.tryParse(matchInfo['startDate']?.toString() ?? '0') ?? 0,
      endDate: int.tryParse(matchInfo['endDate']?.toString() ?? '0') ?? 0,
      venue: venueInfo['ground'] as String? ?? '',
      status: matchInfo['state'] as String? ?? 'Upcoming',
      lineupStatus: 'Pending',
      playingXI: const [],
      leagueId: json['leagueId'] as String?,
      seriesId: matchInfo['seriesId'] as int? ?? 0,
      team1Id: team1['teamId'] as int? ?? 0,
      team2Id: team2['teamId'] as int? ?? 0,
    );
  }

  factory CricketMatchModel.fromMap(Map<String, dynamic> map) {
    return CricketMatchModel(
      id: map['id'] as int? ?? 0,
      seriesName: map['seriesName'] as String? ?? '',
      matchDesc: map['matchDesc'] as String? ?? '',
      matchFormat: map['matchFormat'] as String? ?? '',
      team1Name: map['team1Name'] as String? ?? '',
      team1ShortName: map['team1ShortName'] as String? ?? '',
      team1Img: map['team1Img'] as String? ?? '',
      team2Name: map['team2Name'] as String? ?? '',
      team2ShortName: map['team2ShortName'] as String? ?? '',
      team2Img: map['team2Img'] as String? ?? '',
      startDate: map['startDate'] as int? ?? 0,
      endDate: map['endDate'] as int? ?? 0,
      venue: map['venue'] as String? ?? '',
      status: map['status'] as String? ?? 'Upcoming',
      lineupStatus: map['lineupStatus'] as String? ?? 'Pending',
      playingXI: (map['playingXI'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      leagueId: map['leagueId'] as String?,
      seriesId: map['seriesId'] as int? ?? 0,
      team1Id: map['team1Id'] as int? ?? 0,
      team2Id: map['team2Id'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seriesName': seriesName,
      'matchDesc': matchDesc,
      'matchFormat': matchFormat,
      'team1Name': team1Name,
      'team1ShortName': team1ShortName,
      'team1Img': team1Img,
      'team2Name': team2Name,
      'team2ShortName': team2ShortName,
      'team2Img': team2Img,
      'startDate': startDate,
      'endDate': endDate,
      'venue': venue,
      'status': status,
      'lineupStatus': lineupStatus,
      'playingXI': playingXI,
      'leagueId': leagueId,
      'seriesId': seriesId,
      'team1Id': team1Id,
      'team2Id': team2Id,
    };
  }
}
