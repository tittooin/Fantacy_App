import requests

URL = "https://fantasy-cricket-api.moremagical4.workers.dev/api/matches"
response = requests.get(URL)
data = response.json()

completed_matches = [m for m in data.get('matches', []) if m.get('status') == 'Completed']

if completed_matches:
    m = completed_matches[0]
    print(f"MATCH_ID: {m['id']}")
    print(f"TITLE: {m['title']}")
else:
    print("NO_COMPLETED_MATCHES")
