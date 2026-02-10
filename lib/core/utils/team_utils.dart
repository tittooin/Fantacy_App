
class TeamUtils {
  static final Map<String, String> _flagMap = {
    'IND': 'https://flagcdn.com/w80/in.png',
    'India': 'https://flagcdn.com/w80/in.png',
    'AUS': 'https://flagcdn.com/w80/au.png',
    'Australia': 'https://flagcdn.com/w80/au.png',
    'ENG': 'https://flagcdn.com/w80/gb-eng.png',
    'England': 'https://flagcdn.com/w80/gb-eng.png',
    'NZ': 'https://flagcdn.com/w80/nz.png',
    'New Zealand': 'https://flagcdn.com/w80/nz.png',
    'RSA': 'https://flagcdn.com/w80/za.png',
    'South Africa': 'https://flagcdn.com/w80/za.png',
    'PAK': 'https://flagcdn.com/w80/pk.png',
    'Pakistan': 'https://flagcdn.com/w80/pk.png',
    'SL': 'https://flagcdn.com/w80/lk.png',
    'Sri Lanka': 'https://flagcdn.com/w80/lk.png',
    'BAN': 'https://flagcdn.com/w80/bd.png',
    'Bangladesh': 'https://flagcdn.com/w80/bd.png',
    'AFG': 'https://flagcdn.com/w80/af.png',
    'Afghanistan': 'https://flagcdn.com/w80/af.png',
    'WI': 'https://apps.khelchamps.com/images/flags/wi.png', // West Indies often special case
    'West Indies': 'https://apps.khelchamps.com/images/flags/wi.png',
    'ZIM': 'https://flagcdn.com/w80/zw.png',
    'Zimbabwe': 'https://flagcdn.com/w80/zw.png',
    'IRE': 'https://flagcdn.com/w80/ie.png',
    'Ireland': 'https://flagcdn.com/w80/ie.png',
    'NED': 'https://flagcdn.com/w80/nl.png',
    'Netherlands': 'https://flagcdn.com/w80/nl.png',
    'SCO': 'https://flagcdn.com/w80/gb-sct.png',
    'Scotland': 'https://flagcdn.com/w80/gb-sct.png',
    'NAM': 'https://flagcdn.com/w80/na.png',
    'Namibia': 'https://flagcdn.com/w80/na.png',
    'UAE': 'https://flagcdn.com/w80/ae.png',
    'United Arab Emirates': 'https://flagcdn.com/w80/ae.png',
    'NEP': 'https://flagcdn.com/w80/np.png',
    'Nepal': 'https://flagcdn.com/w80/np.png',
    'USA': 'https://flagcdn.com/w80/us.png',
    'United States': 'https://flagcdn.com/w80/us.png',
    'OMN': 'https://flagcdn.com/w80/om.png',
    'Oman': 'https://flagcdn.com/w80/om.png',
    'PNG': 'https://flagcdn.com/w80/pg.png',
    'Papua New Guinea': 'https://flagcdn.com/w80/pg.png',
    'CAN': 'https://flagcdn.com/w80/ca.png',
    'Canada': 'https://flagcdn.com/w80/ca.png',
    'UGA': 'https://flagcdn.com/w80/ug.png',
    'Uganda': 'https://flagcdn.com/w80/ug.png',
  };

  static String getFlagUrl(String teamName, {String? fallbackUrl}) {
    // 1. Try mapping the team name directly
    if (_flagMap.containsKey(teamName)) return _flagMap[teamName]!;

    // 2. Try partial matches (e.g. "India Women" -> "India")
    for (final key in _flagMap.keys) {
      if (teamName.contains(key)) return _flagMap[key]!;
    }

    // 3. Helper for common short names logic
    final upper = teamName.toUpperCase();
    if (_flagMap.containsKey(upper)) return _flagMap[upper]!;

    // 4. Return provided fallback URL from API if available and not empty
    if (fallbackUrl != null && fallbackUrl.isNotEmpty) return fallbackUrl;

    // 5. Ultimate fallback (maybe a placeholder graphic)
    // return 'https://placehold.co/80?text=${teamName[0]}'; 
    return ''; // Return empty to let UI show initial char
  }
}
