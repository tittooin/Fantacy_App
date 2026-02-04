
const RAPID_API_KEY = '70a8792460msh629f8e0af8cc36bp17accbjsn7c270b8814ee';
const HOST = 'free-cricbuzz-cricket-api.p.rapidapi.com';

async function fetchTeamRoster(teamId, key, host) {
    // Endpoint logic
    const isFree = host.includes('free');
    const endpoint = isFree ? `/cricket-team-squad` : `/teams/get-players`;
    const url = `https://${host}${endpoint}?teamId=${teamId}`;
    console.log(`fetching: ${url}`);

    try {
        const resp = await fetch(url, { headers: { 'x-rapidapi-key': key, 'x-rapidapi-host': host } });
        console.log(`Status: ${resp.status}`);

        if (!resp.ok) return [];

        const data = await resp.json();
        // console.log("Raw Data:", JSON.stringify(data, null, 2).substring(0, 500));

        const list = isFree
            ? (data.response?.players || data.players)
            : (data.player || []);

        if (!list || !Array.isArray(list)) return [];

        return list.map(p => ({
            id: (p.id || p.playerId).toString(),
            name: p.name,
            role: p.role || 'Unknown',
            image: p.image || p.faceImageId || ''
        }));
    } catch (e) {
        console.log(`Error fetching roster for team ${teamId}: ${e.message}`);
        return [];
    }
}

async function run() {
    console.log("Testing Team ID 27 (Ireland) on Backup Host...");
    const roster = await fetchTeamRoster('27', RAPID_API_KEY, HOST);
    console.log(`\nFound ${roster.length} players.`);
    if (roster.length > 0) console.log(roster[0]);
}

run();
