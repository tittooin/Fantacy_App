
async function checkWallet() {
    const workerUrl = 'https://fantasy-cricket-api.moremagical4.workers.dev';
    const userId = '7x6okKn2l5XJVLOBTpzjy6HFXrN2';

    console.log(`🔍 Checking Wallet for ${userId}...`);

    // 1. Check Balance
    try {
        const balRes = await fetch(`${workerUrl}/api/wallet/balance?userId=${userId}`);
        const balData = await balRes.json();
        console.log("💰 Balance:", balData);
    } catch (e) {
        console.error("❌ Balance Fetch Error:", e.message);
    }

    // 2. Check Transactions
    try {
        const txnRes = await fetch(`${workerUrl}/api/transactions/my?userId=${userId}`);
        // console.log("Status:", txnRes.status);
        const txnData = await txnRes.json();
        console.log("📜 Transactions:", JSON.stringify(txnData, null, 2));
    } catch (e) {
        console.error("❌ Transaction Fetch Error:", e.message);
    }
}

checkWallet();
