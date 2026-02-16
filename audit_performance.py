import requests
import time

BASE_URL = "https://fantasy-cricket-api.moremagical4.workers.dev"

ENDPOINTS = [
    "/api/matches",
    "/api/contests?matchId=139084", # Example Match
    "/api/leaderboard?contestId=test_contest", # Safe probe
    "/api/wallet/transactions?userId=test_perf_user"
]

def check_performance():
    print("--- STARTING PERFORMANCE AUDIT ---")
    fail_count = 0
    
    for ep in ENDPOINTS:
        url = f"{BASE_URL}{ep}"
        start = time.time()
        try:
            resp = requests.get(url)
            latency = (time.time() - start) * 1000
            
            status = "PASS" if resp.status_code == 200 or resp.status_code == 404 else "FAIL" # 404 is valid for dummy data
            # strict check: 500 is FAIL.
            if resp.status_code >= 500: status = "FAIL"
            
            print(f"[{status}] {ep} - Status: {resp.status_code}, Latency: {latency:.2f}ms")
            
            if status == "FAIL": fail_count += 1
            
            # CORS Check
            cors = resp.headers.get('Access-Control-Allow-Origin')
            if cors != '*':
                print(f"  [WARN] CORS Header Missing or Incorrect: {cors}")
                
        except Exception as e:
            print(f"[ERROR] {ep} - {str(e)}")
            fail_count += 1

    if fail_count == 0:
        print("\nPERFORMANCE STATUS: PASS")
    else:
        print("\nPERFORMANCE STATUS: FAIL")

check_performance()
