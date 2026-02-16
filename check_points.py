import requests

BASE_URL = "https://fantasy-cricket-api.moremagical4.workers.dev"

def check_all_matches_for_points():
    matches_resp = requests.get(f"{BASE_URL}/api/matches")
    matches = matches_resp.json().get('matches', [])
    
    print(f"Total Matches: {len(matches)}")
    
    for match in matches:
        match_id = match['id']
        points_resp = requests.get(f"{BASE_URL}/fantasy-points", params={'match_id': match_id})
        points_data = points_resp.json()
        
        if points_data.get('success') and points_data.get('points'):
            print(f"FOUND_POINTS: {match_id} ({match['title']})")
            print(f"SAMPLE_PLAYER: {points_data['points'][0]['player_name']}")
            print(f"POINTS_COUNT: {len(points_data['points'])}")
            return match_id, points_data['points']
            
    print("NO_POINTS_FOUND_IN_ANY_MATCH")
    return None

check_all_matches_for_points()
