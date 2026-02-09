
// Seeds a test user in Firestore via REST API
const PROJECT_ID = "axevora11";
const API_KEY = "AIzaSyDVoZoy6_Qz36Xz3P7CbkGSB75Vq0CsJhU";

async function seedUser() {
    const userId = "test_user_vouch_01";
    console.log(`🌱 Seeding Firestore User: ${userId}...`);

    const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${userId}?key=${API_KEY}`;

    // Structure for Firestore REST API (v1)
    const body = {
        fields: {
            walletBalance: { doubleValue: 100 },
            name: { stringValue: "Test User V" },
            email: { stringValue: "test@vouch.com" }
        }
    };

    try {
        // Use PATCH to upsert
        const res = await fetch(url, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body)
        });

        if (res.ok) {
            console.log("✅ User Seeded Successfully!");
            const d = await res.json();
            console.log("Updated At:", d.updateTime);
        } else {
            console.error("❌ Failed:", res.status, await res.text());
        }
    } catch (e) {
        console.error("Error:", e);
    }
}

seedUser();
