import requests
import json

BASE_URL = "https://fantasy-cricket-api.moremagical4.workers.dev"
MATCH_ID = "999999"

resp = requests.get(f"{BASE_URL}/fantasy-points", params={'match_id': MATCH_ID})
data = resp.json()

print(json.dumps(data, indent=2))

# Also fetch scorecard
sc_resp = requests.get(f"{BASE_URL}/api/scorecard/{MATCH_ID}")
print("SCORECARD STATUS:", sc_resp.status_code)
if sc_resp.status_code == 200:
    print(json.dumps(sc_resp.json(), indent=2))
