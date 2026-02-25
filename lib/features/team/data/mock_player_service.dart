import 'package:axevora11/features/team/domain/player_model.dart';

class MockPlayerService {
  static List<PlayerModel> getMockPlayers(String team1, String team2) {
    // Return combined squad for both teams
    return [
      ..._getSquad(team1),
      ..._getSquad(team2),
    ];
  }

  static List<PlayerModel> _getSquad(String team) {
    if (team == 'CSK') {
      return [
        const PlayerModel(id: 'c1', name: 'MS Dhoni', teamShortName: 'CSK', role: PlayerRole.wicketKeeper, credits: 9.5, imageUrl: '1'),
        const PlayerModel(id: 'c2', name: 'R Gaikwad', teamShortName: 'CSK', role: PlayerRole.batsman, credits: 9.0, imageUrl: '2'),
        const PlayerModel(id: 'c3', name: 'D Conway', teamShortName: 'CSK', role: PlayerRole.batsman, credits: 8.5, imageUrl: '3'),
        const PlayerModel(id: 'c4', name: 'R Jadeja', teamShortName: 'CSK', role: PlayerRole.allRounder, credits: 9.5, imageUrl: '4'),
        const PlayerModel(id: 'c5', name: 'S Dube', teamShortName: 'CSK', role: PlayerRole.allRounder, credits: 8.0, imageUrl: '5'),
        const PlayerModel(id: 'c6', name: 'M Ali', teamShortName: 'CSK', role: PlayerRole.allRounder, credits: 8.5, imageUrl: '6'),
        const PlayerModel(id: 'c7', name: 'D Chahar', teamShortName: 'CSK', role: PlayerRole.bowler, credits: 8.5, imageUrl: '7'),
        const PlayerModel(id: 'c8', name: 'M Pathirana', teamShortName: 'CSK', role: PlayerRole.bowler, credits: 8.0, imageUrl: '8'),
        const PlayerModel(id: 'c9', name: 'M Theekshana', teamShortName: 'CSK', role: PlayerRole.bowler, credits: 8.0, imageUrl: '9'),
        const PlayerModel(id: 'c10', name: 'T Deshpande', teamShortName: 'CSK', role: PlayerRole.bowler, credits: 7.5, imageUrl: '10'),
        const PlayerModel(id: 'c11', name: 'A Rahane', teamShortName: 'CSK', role: PlayerRole.batsman, credits: 8.0, imageUrl: '11'),
      ];
    } else if (team == 'MI' || team == 'AUS') { // Fallback for AUS as well
      return [
        const PlayerModel(id: 'm1', name: 'I Kishan', teamShortName: 'MI', role: PlayerRole.wicketKeeper, credits: 9.0, imageUrl: '12'),
        const PlayerModel(id: 'm2', name: 'R Sharma', teamShortName: 'MI', role: PlayerRole.batsman, credits: 9.5, imageUrl: '13'),
        const PlayerModel(id: 'm3', name: 'S Yadav', teamShortName: 'MI', role: PlayerRole.batsman, credits: 9.5, imageUrl: '14'),
        const PlayerModel(id: 'm4', name: 'H Pandya', teamShortName: 'MI', role: PlayerRole.allRounder, credits: 9.0, imageUrl: '15'),
        const PlayerModel(id: 'm5', name: 'T David', teamShortName: 'MI', role: PlayerRole.batsman, credits: 8.0, imageUrl: '16'),
        const PlayerModel(id: 'm6', name: 'C Green', teamShortName: 'MI', role: PlayerRole.allRounder, credits: 9.0, imageUrl: '17'),
        const PlayerModel(id: 'm7', name: 'J Bumrah', teamShortName: 'MI', role: PlayerRole.bowler, credits: 9.5, imageUrl: '18'),
        const PlayerModel(id: 'm8', name: 'P Chawla', teamShortName: 'MI', role: PlayerRole.bowler, credits: 7.5, imageUrl: '19'),
        const PlayerModel(id: 'm9', name: 'J Behrendorff', teamShortName: 'MI', role: PlayerRole.bowler, credits: 8.0, imageUrl: '20'),
        const PlayerModel(id: 'm10', name: 'A Madhwal', teamShortName: 'MI', role: PlayerRole.bowler, credits: 7.5, imageUrl: '21'),
        const PlayerModel(id: 'm11', name: 'Tilak V', teamShortName: 'MI', role: PlayerRole.batsman, credits: 8.0, imageUrl: '22'),
      ];
    }
    // Generic Fallback
    return List.generate(11, (index) => PlayerModel(
      id: '${team}_$index', 
      name: '$team Player $index', 
      teamShortName: team, 
      role: index == 0 ? PlayerRole.wicketKeeper : (index < 5 ? PlayerRole.batsman : (index < 8 ? PlayerRole.allRounder : PlayerRole.bowler)), 
      credits: 8.0 + (index % 2), 
      imageUrl: ''
    ));
  }
}
