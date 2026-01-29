const axios = require('axios');

async function testLiveOrder() {
    const workerUrl = "https://fantasy-cricket-api.moremagical4.workers.dev/api/create-payment";

    // Random Order ID component to avoid duplicacy
    const dummyUserId = "test_user_" + Math.floor(Math.random() * 1000);

    console.log(`🚀 Testing Live Worker: ${workerUrl}`);
    console.log(`👤 User: ${dummyUserId}, Amount: ₹1.00`);

    try {
        const response = await axios.post(workerUrl, {
            userId: dummyUserId,
            amount: 1.00
        });

        console.log("\n✅ Response from Worker:");
        console.log(JSON.stringify(response.data, null, 2));

        if (response.data.success && response.data.paymentLink) {
            console.log("\n🎉 SUCCESS! Cashfree returned a valid payment link.");
            console.log("This proves: 1. Worker is reachable. 2. Cashfree Keys are Valid.");
        } else {
            console.log("\n⚠️ Partial Success or Error in logic.");
        }

    } catch (error) {
        console.error("\n❌ Request Failed:");
        if (error.response) {
            console.error(`Status: ${error.response.status}`);
            console.error("Data:", error.response.data);
        } else {
            console.error(error.message);
        }
    }
}

testLiveOrder();
