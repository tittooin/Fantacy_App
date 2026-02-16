import requests

BASE_URL = "https://fantasy-cricket-api.moremagical4.workers.dev"

def find_proof_match():
    matches_resp = requests.get(f"{BASE_URL}/api/matches")
    matches = matches_resp.json().get('matches', [])
    
    for match in matches:
        match_id = match['id']
        if str(match_id) == "999999": continue
        
        points_resp = requests.get(f"{BASE_URL}/fantasy-points", params={'match_id': match_id})
        points_data = points_resp.json()
        
        if points_data.get('success') and points_data.get('points'):
            sc_resp = requests.get(f"{BASE_URL}/api/scorecard/{match_id}")
            if sc_resp.status_code == 200:
                print(f"PROOF_MATCH_FOUND: {match_id} ({match['title']})")
                return match_id
                
    print("NO_PROOF_MATCH_FOUND")
    return None

find_proof_match()
