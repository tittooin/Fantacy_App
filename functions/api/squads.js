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

    // Endpoint: /mcenter/v1/{matchId}/scov2
    const targetUrl = `https://${apiHost}/mcenter/v1/${matchId}/scov2`;

    try {
        const response = await fetch(targetUrl, {
            method: "GET",
            headers: {
                "X-RapidAPI-Key": apiKey,
                "X-RapidAPI-Host": apiHost
            }
        });

        const data = await response.json();
        return new Response(JSON.stringify(data), {
            headers: {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            }
        });
    } catch (err) {
        return new Response(JSON.stringify({ error: err.message }), { status: 500 });
    }
}
