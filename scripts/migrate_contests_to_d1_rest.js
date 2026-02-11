/**
 * Firestore to D1 Contest Migration Script (REST API Version)
 * 
 * This script safely migrates contests from Firestore to D1 database
 * using Firestore REST API with batching to avoid quota limits.
 * 
 * Usage: node scripts/migrate_contests_to_d1_rest.js
 */

const FIREBASE_PROJECT_ID = 'axevora11';
const FIREBASE_API_KEY = 'AIzaSyDVoZoy6_Qz36Xz3P7CbkGSB75Vq0CsJhU'; // From wrangler.toml
const WORKER_URL = 'https://fantasy-cricket-api.moremagical4.workers.dev';
const BATCH_SIZE = 50;

async function fetchFirestoreContests(pageToken = null) {
    const baseUrl = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/contests`;

    let url = `${baseUrl}?pageSize=${BATCH_SIZE}`;
    if (pageToken) {
        url += `&pageToken=${pageToken}`;
    }

    const response = await fetch(url, {
        headers: {
            'Authorization': `Bearer ${FIREBASE_API_KEY}`
        }
    });

    if (!response.ok) {
        throw new Error(`Firestore API Error: ${response.status} ${response.statusText}`);
    }

    return await response.json();
}

function parseFirestoreValue(value) {
    if (!value) return null;

    if (value.stringValue !== undefined) return value.stringValue;
    if (value.integerValue !== undefined) return parseInt(value.integerValue);
    if (value.doubleValue !== undefined) return parseFloat(value.doubleValue);
    if (value.booleanValue !== undefined) return value.booleanValue;
    if (value.timestampValue !== undefined) return new Date(value.timestampValue).getTime();
    if (value.arrayValue) {
        return value.arrayValue.values?.map(v => parseFirestoreValue(v)) || [];
    }
    if (value.mapValue) {
        const obj = {};
        for (const [key, val] of Object.entries(value.mapValue.fields || {})) {
            obj[key] = parseFirestoreValue(val);
        }
        return obj;
    }

    return null;
}

function parseFirestoreDocument(doc) {
    const fields = doc.fields || {};
    const parsed = {};

    for (const [key, value] of Object.entries(fields)) {
        parsed[key] = parseFirestoreValue(value);
    }

    // Extract document ID from name (format: projects/.../databases/.../documents/contests/{id})
    const pathParts = doc.name.split('/');
    parsed.id = pathParts[pathParts.length - 1];

    return parsed;
}

async function migrateContests() {
    console.log('🚀 Starting Firestore to D1 Contest Migration (REST API)...\n');

    try {
        let pageToken = null;
        let totalMigrated = 0;
        let totalFailed = 0;
        let batchNumber = 1;

        while (true) {
            console.log(`📦 Processing Batch ${batchNumber}...`);

            const data = await fetchFirestoreContests(pageToken);

            if (!data.documents || data.documents.length === 0) {
                console.log('✅ No more contests to migrate.\n');
                break;
            }

            // Process each contest in the batch
            for (const doc of data.documents) {
                const contest = parseFirestoreDocument(doc);
                const contestId = contest.id;

                try {
                    // Prepare contest data for D1
                    const d1Contest = {
                        id: contestId,
                        matchId: (contest.matchId || contest.match_id || '').toString(),
                        entryFee: contest.entryFee || 0,
                        totalSpots: contest.totalSpots || 100,
                        filledSpots: contest.filledSpots || 0,
                        prizePool: contest.prizePool || 0,
                        category: contest.category || 'Mega Contest',
                        isGuaranteed: contest.isGuaranteed || false,
                        isFlexible: contest.isFlexible || false,
                        winningBreakdown: contest.winningBreakdown || [],
                        createdAt: contest.createdAt || Date.now()
                    };

                    // Insert into D1 via Worker API
                    const response = await fetch(`${WORKER_URL}/api/admin/contests/create`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify(d1Contest)
                    });

                    const result = await response.json();

                    if (result.success) {
                        console.log(`  ✅ Migrated: ${contestId} (Match: ${d1Contest.matchId}, Fee: ₹${d1Contest.entryFee})`);
                        totalMigrated++;
                    } else {
                        console.error(`  ❌ Failed: ${contestId} - ${result.error}`);
                        totalFailed++;
                    }

                    // Small delay to avoid rate limiting
                    await new Promise(resolve => setTimeout(resolve, 100));

                } catch (error) {
                    console.error(`  ❌ Error migrating ${contestId}:`, error.message);
                    totalFailed++;
                }
            }

            // Check for next page
            pageToken = data.nextPageToken;
            if (!pageToken) {
                console.log('✅ Reached end of contests collection.\n');
                break;
            }

            batchNumber++;
            console.log(`✅ Batch ${batchNumber - 1} complete. Total migrated: ${totalMigrated}, Failed: ${totalFailed}\n`);

            // Delay between batches to avoid quota limits
            await new Promise(resolve => setTimeout(resolve, 1000));
        }

        console.log(`\n🎉 Migration Complete!`);
        console.log(`📊 Total Contests Migrated: ${totalMigrated}`);
        console.log(`❌ Total Failed: ${totalFailed}`);

    } catch (error) {
        console.error('❌ Migration Error:', error);
        process.exit(1);
    }

    process.exit(0);
}

// Run migration
migrateContests();
