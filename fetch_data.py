import requests
import json

MATCH_ID = "124920"
BASE_URL = "https://fantasy-cricket-api.moremagical4.workers.dev/api"

print(f"--- FETCHING DATA FOR MATCH {MATCH_ID} ---")

# 1. Fetch Scorecard
scorecard_resp = requests.get(f"{BASE_URL}/scorecard/{MATCH_ID}")
scorecard = scorecard_resp.json()

# 2. Fetch Stored Points
points_resp = requests.get(f"https://fantasy-cricket-api.moremagical4.workers.dev/fantasy-points?match_id={MATCH_ID}")
points_data = points_resp.json()

# Save for reference
with open("scorecard_debug.json", "w") as f:
    json.dump(scorecard, f, indent=2)

with open("points_debug.json", "w") as f:
    json.dump(points_data, f, indent=2)

print("DATA SAVED TO scorecard_debug.json and points_debug.json")

# Extract a sample player
if points_data.get('success') and points_data.get('points'):
    sample_player = points_data['points'][0]
    print(f"SAMPLE_PLAYER_IN_D1: {sample_player['player_name']} (ID: {sample_player['player_id']}) -> Points: {sample_player['total_points']}")
else:
    print("NO_POINTS_DATA_FOUND")
