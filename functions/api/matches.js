export async function onRequestGet(context) {
    const apiKey = context.env.RAPID_API_KEY;
    const apiHost = "cricbuzz-cricket.p.rapidapi.com";

    if (!apiKey) {
        return new Response(JSON.stringify({ error: "Configuration Error: RAPID_API_KEY missing" }), {
            status: 500,
            headers: { "Content-Type": "application/json" }
        });
    }

    // Use List Upcoming for safer wide data, or v1/upcoming if preferred.
    // Using v1/upcoming as established.
    const url = `https://${apiHost}/matches/v1/upcoming`;

    try {
        const response = await fetch(url, {
            method: "GET",
            headers: {
                "X-RapidAPI-Key": apiKey,
                "X-RapidAPI-Host": apiHost
            }
        });

        if (!response.ok) {
            return new Response(JSON.stringify({ error: `Upstream API Error: ${response.status}` }), {
                status: response.status,
                headers: { "Content-Type": "application/json" }
            });
        }

        const data = await response.json();
        return new Response(JSON.stringify(data), {
            headers: {
                "Content-Type": "application/json",
                // Allow CORS if needed, though same-origin is default
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
