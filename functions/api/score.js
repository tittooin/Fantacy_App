export async function onRequestGet(context) {
    const apiKey = context.env.RAPID_API_KEY;
    const apiHost = "cricbuzz-cricket2.p.rapidapi.com";

    if (!apiKey) {
        return new Response(JSON.stringify({ error: "Configuration Error" }), { status: 500 });
    }

    const url = new URL(context.request.url);
    const matchId = url.searchParams.get("id");

    if (!matchId) {
        return new Response(JSON.stringify({ error: "Missing matchId" }), { status: 400 });
    }

    const headers = {
        "X-RapidAPI-Key": apiKey,
        "X-RapidAPI-Host": apiHost
    };

    try {
        // Fetch Mini Score (Lightweight)
        const fetchUrl = `https://${apiHost}/mcenter/v1/${matchId}/scov2`;
        const resp = await fetch(fetchUrl, { headers });

        if (!resp.ok) {
            return new Response(JSON.stringify({ error: "Failed to fetch score" }), { status: resp.status });
        }

        const data = await resp.json();

        // Pass-through Raw JSON
        // The Client (Flutter) will handle parsing for Points Calculation.
        return new Response(JSON.stringify(data), {
            headers: { "Content-Type": "application/json" }
        });

    } catch (err) {
        return new Response(JSON.stringify({ error: err.message }), { status: 500 });
    }
}
