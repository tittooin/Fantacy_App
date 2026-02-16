import requests

BASE_URL = "https://fantasy-cricket-api.moremagical4.workers.dev"

def find_real_match_with_points():
    matches_resp = requests.get(f"{BASE_URL}/api/matches")
    matches = matches_resp.json().get('matches', [])
    
    # Sort matches by ID descending to get recent ones
    matches.sort(key=lambda x: x['id'], reverse=True)
    
    for match in matches:
        match_id = match['id']
        if str(match_id) == "999999": continue
        
        points_resp = requests.get(f"{BASE_URL}/fantasy-points", params={'match_id': match_id})
        points_data = points_resp.json()
        
        if points_data.get('success') and points_data.get('points'):
            # Double check if it has a proper breakdown
            has_breakdown = any('breakdown' in p for p in points_data['points'])
            if has_breakdown:
                print(f"REAL_MATCH_FOUND: {match_id} ({match['title']})")
                return match_id, points_data['points']
            
    print("NO_REAL_POINTS_FOUND")
    return None

find_real_match_with_points()
