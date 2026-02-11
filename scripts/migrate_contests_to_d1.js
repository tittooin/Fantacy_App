/**
 * Firestore to D1 Contest Migration Script
 * 
 * This script safely migrates contests from Firestore to D1 database
 * with batching to avoid Firestore quota limits.
 */

import admin from 'firebase-admin';
import { readFileSync } from 'fs';

// Initialize Firebase Admin
const serviceAccount = JSON.parse(
    readFileSync('./firebase-service-account.json', 'utf8')
);

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const WORKER_URL = 'https://fantasy-cricket-api.moremagical4.workers.dev';
const BATCH_SIZE = 50; // Process 50 contests at a time to avoid quota limits

async function migrateContests() {
    console.log('🚀 Starting Firestore to D1 Contest Migration...\n');

    try {
        // Fetch all contests from Firestore in batches
        let lastDoc = null;
        let totalMigrated = 0;
        let batchNumber = 1;

        while (true) {
            console.log(`📦 Processing Batch ${batchNumber}...`);

            // Query with pagination
            let query = db.collection('contests')
                .orderBy('createdAt')
                .limit(BATCH_SIZE);

            if (lastDoc) {
                query = query.startAfter(lastDoc);
            }

            const snapshot = await query.get();

            if (snapshot.empty) {
                console.log('✅ No more contests to migrate.\n');
                break;
            }

            // Process each contest in the batch
            for (const doc of snapshot.docs) {
                const contest = doc.data();
                const contestId = doc.id;

                try {
                    // Prepare contest data for D1
                    const d1Contest = {
                        id: contestId,
                        matchId: contest.matchId || contest.match_id,
                        entryFee: contest.entryFee || 0,
                        totalSpots: contest.totalSpots || 100,
                        filledSpots: contest.filledSpots || 0,
                        prizePool: contest.prizePool || 0,
                        category: contest.category || 'Mega Contest',
                        isGuaranteed: contest.isGuaranteed || false,
                        isFlexible: contest.isFlexible || false,
                        winningBreakdown: contest.winningBreakdown || [],
                        createdAt: contest.createdAt?.toMillis?.() || Date.now()
                    };

                    // Insert into D1 via Worker API
                    const response = await fetch(`${WORKER_URL}/api/admin/contests/create`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify(d1Contest)
                    });

                    const result = await response.json();

                    if (result.success) {
                        console.log(`  ✅ Migrated: ${contestId} (Match: ${d1Contest.matchId})`);
                        totalMigrated++;
                    } else {
                        console.error(`  ❌ Failed: ${contestId} - ${result.error}`);
                    }

                    // Small delay to avoid rate limiting
                    await new Promise(resolve => setTimeout(resolve, 100));

                } catch (error) {
                    console.error(`  ❌ Error migrating ${contestId}:`, error.message);
                }
            }

            // Update pagination cursor
            lastDoc = snapshot.docs[snapshot.docs.length - 1];
            batchNumber++;

            console.log(`✅ Batch ${batchNumber - 1} complete. Total migrated so far: ${totalMigrated}\n`);

            // Delay between batches to avoid quota limits
            await new Promise(resolve => setTimeout(resolve, 1000));
        }

        console.log(`\n🎉 Migration Complete!`);
        console.log(`📊 Total Contests Migrated: ${totalMigrated}`);

    } catch (error) {
        console.error('❌ Migration Error:', error);
        process.exit(1);
    }

    process.exit(0);
}

// Run migration
migrateContests();
