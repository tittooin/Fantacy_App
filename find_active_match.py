import requests

BASE_URL = "https://fantasy-cricket-api.moremagical4.workers.dev/api"

def find_match_with_leaderboard():
    # Get all matches
    matches_resp = requests.get(f"{BASE_URL}/matches")
    matches = matches_resp.json().get('matches', [])
    
    for match in matches:
        match_id = match['id']
        # Check contests for this match
        contests_resp = requests.get(f"{BASE_URL}/contests", params={'matchId': match_id})
        contests = contests_resp.json().get('contests', [])
        
        for contest in contests:
            contest_id = contest['id']
            # Check leaderboard
            leader_resp = requests.get(f"{BASE_URL}/leaderboard/{contest_id}")
            leaderboard = leader_resp.json().get('leaderboard', [])
            
            if leaderboard:
                print(f"FOUND_MATCH: {match_id} ({match['title']})")
                print(f"CONTEST_ID: {contest_id}")
                print(f"LEADERBOARD_SIZE: {len(leaderboard)}")
                return match_id, contest_id, leaderboard[0]
                
    print("NO_MATCH_WITH_LEADERBOARD_FOUND")
    return None

find_match_with_leaderboard()
