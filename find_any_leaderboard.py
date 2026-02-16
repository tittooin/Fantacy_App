import requests

BASE_URL = "https://fantasy-cricket-api.moremagical4.workers.dev/api"

def find_any_leaderboard():
    # Get all matches
    matches = requests.get(f"{BASE_URL}/matches").json().get('matches', [])
    
    for m in matches:
        m_id = m['id']
        contests = requests.get(f"{BASE_URL}/contests", params={'matchId': m_id}).json().get('contests', [])
        for c in contests:
            c_id = c['id']
            leader = requests.get(f"{BASE_URL}/leaderboard/{c_id}").json().get('leaderboard', [])
            if leader:
                print(f"WINNER! Match: {m_id}, Contest: {c_id}")
                return m_id, c_id
    print("NOTHING")

find_any_leaderboard()
