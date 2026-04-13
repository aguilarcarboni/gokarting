import requests
import csv
import os
from pprint import pprint

BASE = "https://lt-api.speedhive.com"

EVENT_ID = "E82E774B72637180-2147484742"
SESSION_ID = "E82E774B72637180-2147484742-1073749966"
QUALI_ID = "E82E774B72637180-2147484742-1073749963"

HEADERS = {
    "Accept": "application/json",
    "Origin": "https://speedhive.mylaps.com",
    "Referer": "https://speedhive.mylaps.com/",
    "User-Agent": "Mozilla/5.0",
}

def fetch_api(url: str, params=None) -> dict:
    """Generic function to fetch JSON from the API."""
    resp = requests.get(url, headers=HEADERS, params=params, timeout=30)
    resp.raise_for_status()
    return resp.json()

def fetch_event(event_id: str) -> dict:
    """Fetch event data with sessions."""
    url = f"{BASE}/api/events/{event_id}"
    return fetch_api(url, params={"sessions": "true"})

def fetch_session_data(event_id: str, session_id: str) -> dict:
    """Fetch session data."""
    url = f"{BASE}/api/events/{event_id}/sessions/{session_id}/data"
    return fetch_api(url)

def fetch_session_stats(event_id: str, session_id: str) -> dict:
    """Fetch session stats."""
    url = f"{BASE}/api/events/{event_id}/sessions/{session_id}/stats"
    return fetch_api(url)

def fetch_competitor(event_id: str, session_id: str, competitor_id: str) -> dict:
    """Fetch competitor data."""
    url = f"{BASE}/api/events/{event_id}/sessions/{session_id}/competitor/{competitor_id}"
    return fetch_api(url)

def fetch_trackmap(event_id: str) -> dict:
    """Fetch trackmap data."""
    url = f"{BASE}/api/events/{event_id}/trackmap"
    return fetch_api(url)

def fetch_session_bundle(event_id: str, session_id: str) -> tuple[dict, dict, list]:
    """Fetch session data, session stats, and all competitors' lap data."""
    session_data = fetch_session_data(event_id, session_id)
    session_stats = fetch_session_stats(event_id, session_id)
    competitor_ids = extract_competitor_ids(session_data)
    print(f"Found {len(competitor_ids)} competitors in session {session_id}")
    all_competitors = []

    for idx, competitor_id in enumerate(competitor_ids, 1):
        print(f"  Fetching competitor {idx}/{len(competitor_ids)} (ID: {competitor_id})...")
        try:
            competitor_data = fetch_competitor(event_id, session_id, competitor_id)
            all_competitors.append(competitor_data)
        except Exception as e:
            print(f"    Error fetching competitor {competitor_id}: {e}")

    return session_data, session_stats, all_competitors

def extract_competitor_ids(session_data: dict) -> list:
    """Extract all competitor IDs from session data."""
    competitors = session_data.get('l', [])
    return [str(c['id']) for c in competitors if 'id' in c]

def save_event_to_csv(event: dict, filename: str = "events.csv"):
    """Save event data to CSV."""
    data = {
        'id': event.get('id'),
        'name': event.get('n'),
        'date': event.get('dt'),
        'location': event.get('l', {}).get('c'),
        'track_name': event.get('t', {}).get('n'),
        'track_length_km': event.get('t', {}).get('l'),
    }
    with open(filename, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=data.keys())
        writer.writeheader()
        writer.writerow(data)
    print(f"✓ Saved event data to {filename}")

def save_sessions_to_csv(event: dict, filename: str = "sessions.csv"):
    """Save session data to CSV."""
    sessions = event.get('ss', [])
    if not sessions:
        return
    
    with open(filename, 'w', newline='') as f:
        fieldnames = ['session_id', 'event_id', 'event_name', 'day', 'run_name', 'run_type', 'start_time', 'best_lap_time']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        
        for session in sessions:
            writer.writerow({
                'session_id': session.get('id'),
                'event_id': session.get('eId'),
                'event_name': session.get('eNam'),
                'day': session.get('gNam'),
                'run_name': session.get('rnNam'),
                'run_type': session.get('rnTp'),
                'start_time': session.get('stod'),
                'best_lap_time': session.get('btLpTim', ''),
            })
    print(f"✓ Saved {len(sessions)} sessions to {filename}")

def save_session_stats_to_csv(stats: dict, filename: str = "session_stats.csv"):
    """Save session stats to CSV."""
    data = {
        'session_id': stats.get('sesId'),
        'run_name': stats.get('rnNam'),
        'event_id': stats.get('eId'),
        'best_lap_driver': stats.get('bestLapDriverName'),
        'best_lap_time': stats.get('bestLapTime'),
        'total_laps': stats.get('tLs'),
        'total_laps_leader': stats.get('tLsLdr'),
        'num_participants': stats.get('numPar'),
        'num_positions': stats.get('numPs'),
    }
    with open(filename, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=data.keys())
        writer.writeheader()
        writer.writerow(data)
    print(f"✓ Saved session stats to {filename}")

def save_results_to_csv(session_data: dict, filename: str = "results.csv"):
    """Save session results (all competitors' final positions) to CSV."""
    competitors = session_data.get('l', [])
    
    with open(filename, 'w', newline='') as f:
        fieldnames = [
            'position', 'driver_name', 'driver_number', 'competitor_id',
            'laps_completed', 'best_lap_time', 'last_lap_time',
            'total_time', 'gap_to_leader', 'gap_to_previous',
            'avg_speed', 'avg_time', 'marker', 'finished'
        ]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        
        for competitor in competitors:
            writer.writerow({
                'position': competitor.get('pos'),
                'driver_name': competitor.get('nam'),
                'driver_number': competitor.get('no'),
                'competitor_id': competitor.get('id'),
                'laps_completed': competitor.get('ls'),
                'best_lap_time': competitor.get('btTm', ''),
                'last_lap_time': competitor.get('lsTm', ''),
                'total_time': competitor.get('tTm', ''),
                'gap_to_leader': competitor.get('df', ''),
                'gap_to_previous': competitor.get('gp', ''),
                'avg_speed': competitor.get('avSp', ''),
                'avg_time': competitor.get('avTm', ''),
                'marker': competitor.get('mkr'),
                'finished': competitor.get('if'),
            })
    print(f"✓ Saved {len(competitors)} results to {filename}")

def save_competitor_laps_to_csv(all_competitors: list, filename: str = "competitor_laps.csv"):
    """Save detailed lap data for all competitors to CSV."""
    with open(filename, 'w', newline='') as f:
        fieldnames = [
            'competitor_id', 'driver_name', 'driver_number',
            'lap_number', 'lap_time', 'last_time_of_day',
            'gap_to_leader', 'gap_to_previous', 'gap_to_best',
            'is_best_lap', 'finished', 'sector1', 'sector2', 'sector3'
        ]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        
        for competitor in all_competitors:
            results = competitor.get('results', [])
            if not results:
                continue
            
            driver_info = results[0] if results else {}
            driver_id = driver_info.get('id', '')
            driver_name = driver_info.get('nam', '')
            driver_number = driver_info.get('no', '')
            
            for result in results:
                writer.writerow({
                    'competitor_id': driver_id,
                    'driver_name': driver_name,
                    'driver_number': driver_number,
                    'lap_number': result.get('ls'),
                    'lap_time': result.get('lsTm', ''),
                    'last_time_of_day': result.get('lsTod', ''),
                    'gap_to_leader': result.get('df', ''),
                    'gap_to_previous': result.get('gp', ''),
                    'gap_to_best': result.get('gpb', ''),
                    'is_best_lap': result.get('btCl'),
                    'finished': result.get('if'),
                    'sector1': result.get('s0', ''),
                    'sector2': result.get('s1', ''),
                    'sector3': result.get('s2', ''),
                })
    print(f"✓ Saved lap data for {len(all_competitors)} competitors to {filename}")

def save_trackmap_to_csv(trackmap: dict, filename: str = "trackmap.csv"):
    """Save trackmap coordinates to CSV."""
    points = trackmap.get('p', [])
    
    with open(filename, 'w', newline='') as f:
        fieldnames = ['track_id', 'track_name', 'latitude', 'longitude', 'point_index']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        
        for idx, point in enumerate(points):
            writer.writerow({
                'track_id': trackmap.get('id'),
                'track_name': trackmap.get('n'),
                'latitude': point[0],
                'longitude': point[1],
                'point_index': idx,
            })
    print(f"✓ Saved {len(points)} trackmap points to {filename}")

def export_session_csvs(prefix: str, session_data: dict, session_stats: dict, all_competitors: list):
    """Save session CSVs with an optional prefix."""
    save_session_stats_to_csv(session_stats, filename=f"{prefix}session_stats.csv")
    save_results_to_csv(session_data, filename=f"{prefix}results.csv")
    save_competitor_laps_to_csv(all_competitors, filename=f"{prefix}competitor_laps.csv")


def main():
    print("Fetching event data...")
    event = fetch_event(EVENT_ID)
    pprint(event)
    print("\n" + "="*50 + "\n")

    print("Fetching trackmap...")
    trackmap = fetch_trackmap(EVENT_ID)
    pprint(trackmap)
    print("\n" + "="*50 + "\n")

    print("Fetching normal session bundle...")
    session_data, session_stats, all_competitors = fetch_session_bundle(EVENT_ID, SESSION_ID)
    print(f"\nSuccessfully fetched normal session bundle ({len(all_competitors)} competitors)")
    print("\n" + "="*50 + "\n")

    print("Fetching quali session bundle...")
    quali_data, quali_stats, quali_competitors = fetch_session_bundle(EVENT_ID, QUALI_ID)
    print(f"\nSuccessfully fetched quali session bundle ({len(quali_competitors)} competitors)")
    print("\n" + "="*50 + "\n")

    print("Saving data to CSV files...")
    save_event_to_csv(event)
    save_sessions_to_csv(event)
    save_trackmap_to_csv(trackmap)

    export_session_csvs(prefix="", session_data=session_data, session_stats=session_stats, all_competitors=all_competitors)
    export_session_csvs(prefix="quali_", session_data=quali_data, session_stats=quali_stats, all_competitors=quali_competitors)

    print("✓ All data exported successfully!")

if __name__ == "__main__":
    main()