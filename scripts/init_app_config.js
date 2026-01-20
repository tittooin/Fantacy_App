
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // User needs to provide this or I use another way

// Note: This script is a template. 
// Since I don't have the service account key, I will guide the user 
// or use a different method (e.g. Firebase Console).
// Actually, I'll just give the user the structure.

/*
Collection: app_config
Document ID: general
Fields:
  latest_version: "1.0.0" (String)
  force_update: false (Boolean)
  update_url: "https://axevora11.in/app-release.apk" (String)
*/

console.log("Please create the following in Firestore Console:");
console.log("Collection: app_config");
console.log("Document: general");
console.log("Fields:");
console.log("- latest_version: \"1.0.0\"");
console.log("- force_update: false");
console.log("- update_url: \"https://axevora11.in/app-release.apk\"");
