import requests
import json

MATCH_ID = "139084"
BASE_URL = "https://fantasy-cricket-api.moremagical4.workers.dev/api"

print(f"--- REAL CALCULATION PROOF: MATCH {MATCH_ID} ---")

# 1. Fetch Scorecard
sc_resp = requests.get(f"{BASE_URL}/scorecard/{MATCH_ID}")
if sc_resp.status_code == 200:
    with open("sc_real.json", "w") as f:
        json.dump(sc_resp.json(), f, indent=2)
    print("Scorecard saved to sc_real.json")
else:
    print(f"FAILED TO FETCH SCORECARD: {sc_resp.status_code}")

# 2. Fetch Points
fp_resp = requests.get(f"https://fantasy-cricket-api.moremagical4.workers.dev/fantasy-points", params={'match_id': MATCH_ID})
if fp_resp.status_code == 200:
    with open("fp_real.json", "w") as f:
        json.dump(fp_resp.json(), f, indent=2)
    print("Fantasy points saved to fp_real.json")
else:
    print(f"FAILED TO FETCH POINTS: {fp_resp.status_code}")
