export async function onRequestGet(context) {
    const apiKey = context.env.RAPID_API_KEY;
    const apiHost = "cricbuzz-cricket2.p.rapidapi.com";

    if (!apiKey) {
        return new Response(JSON.stringify({ error: "Configuration Error" }), { status: 500 });
    }

    const url = new URL(context.request.url);
    const matchId = url.searchParams.get("id");
    const seriesId = url.searchParams.get("seriesId");
    const t1Id = url.searchParams.get("t1Id");
    const t2Id = url.searchParams.get("t2Id");

    if (!matchId) {
        return new Response(JSON.stringify({ error: "Missing matchId" }), { status: 400 });
    }

    const headers = {
        "X-RapidAPI-Key": apiKey,
        "X-RapidAPI-Host": apiHost
    };

    try {
        // 1. Try Fetching Playing XI (scov2) - Best for Live Matches
        // Note: scov2 on V2 API might check different endpoint or return 404 if not live
        try {
            const url1 = `https://${apiHost}/mcenter/v1/${matchId}/scov2`;
            const resp1 = await fetch(url1, { headers });
            if (resp1.ok) {
                const data = await resp1.json();
                if (data.matchInfo && data.matchInfo.team1 && data.matchInfo.team1.playerDetails) {
                    // Add Source Flag
                    data.source = 'playing_xi';
                    return new Response(JSON.stringify(data), {
                        headers: { "Content-Type": "application/json" }
                    });
                }
            }
        } catch (e) {
            // Ignore and try fallback
        }

        // 2. Fallback: Series Squads (Best for Upcoming Matches)
        if (seriesId && t1Id && t2Id) {
            const url2 = `https://${apiHost}/series/v1/${seriesId}/squads`;
            const resp2 = await fetch(url2, { headers });
            if (resp2.ok) {
                const squadData = await resp2.json();
                const squads = squadData.squads;

                // Find Squad IDs
                let t1SquadId = null;
                let t2SquadId = null;

                if (squads) {
                    for (const s of squads) {
                        if (s.teamId == t1Id) t1SquadId = s.squadId;
                        if (s.teamId == t2Id) t2SquadId = s.squadId;
                    }
                }

                // Fetch Individual Squads
                const fetchSquad = async (sid) => {
                    if (!sid) return [];
                    const res = await fetch(`https://${apiHost}/series/v1/${seriesId}/squads/${sid}`, { headers });
                    if (res.ok) {
                        const d = await res.json();
                        return d.player || [];
                    }
                    return [];
                };

                const [p1, p2] = await Promise.all([
                    fetchSquad(t1SquadId),
                    fetchSquad(t2SquadId)
                ]);

                // Construct Response compatible with Dart Parser (Mimic matchInfo structure roughly)
                // Or return a custom structure and update Dart logic.
                // Let's return a "Unified Payload" that Dart can easily parse.

                return new Response(JSON.stringify({
                    isFallback: true,
                    source: 'series_squad',
                    team1: p1,
                    team2: p2
                }), { headers: { "Content-Type": "application/json" } });
            }
        }

        return new Response(JSON.stringify({ error: "No players found" }), { status: 404 });

    } catch (err) {
        return new Response(JSON.stringify({ error: err.message }), { status: 500 });
    }
}
