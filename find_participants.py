import requests

BASE_URL = "https://fantasy-cricket-api.moremagical4.workers.dev/api"

def find_match_with_participants():
    # Get all matches
    matches_resp = requests.get(f"{BASE_URL}/matches")
    matches = matches_resp.json().get('matches', [])
    
    for match in matches:
        match_id = match['id']
        # Check participants
        try:
            audit_resp = requests.get(f"{BASE_URL}/admin/match/participants", params={'matchId': match_id})
            if audit_resp.status_code == 200:
                participants = audit_resp.json().get('participants', [])
                if participants:
                    print(f"FOUND_PARTICIPANTS: {match_id} ({match['title']})")
                    print(f"COUNT: {len(participants)}")
                    return match_id, participants
        except:
            continue
            
    print("NO_PARTICIPANTS_FOUND")
    return None

find_match_with_participants()
