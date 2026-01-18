export async function onRequestGet(context) {
    const apiKey = context.env.RAPID_API_KEY;
    const apiHost = "cricbuzz-cricket.p.rapidapi.com";

    if (!apiKey) {
        return new Response(JSON.stringify({ error: "Configuration Error: RAPID_API_KEY missing" }), {
            status: 500,
            headers: { "Content-Type": "application/json" }
        });
    }

    // SWITCHED TO matches/list-upcoming
    // v1/upcoming was returning 403 (Forbidden)
    const url = `https://${apiHost}/matches/list-upcoming`;

    try {
        const response = await fetch(url, {
            method: "GET",
            headers: {
                "X-RapidAPI-Key": apiKey,
                "X-RapidAPI-Host": apiHost
            }
        });

        if (!response.ok) {
            const errText = await response.text();
            return new Response(JSON.stringify({
                error: `Upstream API Error: ${response.status}`,
                details: errText
            }), {
                status: response.status,
                headers: { "Content-Type": "application/json" }
            });
        }

        const data = await response.json();
        return new Response(JSON.stringify(data), {
            headers: {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            }
        });

    } catch (err) {
        return new Response(JSON.stringify({ error: err.message }), {
            status: 500,
            headers: { "Content-Type": "application/json" }
        });
    }
}
