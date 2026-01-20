const jwt = require('jsonwebtoken');
const fs = require('fs');

// Your specific credentials
const KEY_ID = 'D7KLD62V76';
const TEAM_ID = '2K7NKASVSD';
const SERVICES_ID = 'com.dariusrobu.classlly';
const PRIVATE_KEY_FILE = 'AuthKey_D7KLD62V76.p8';

try {
  // Check if the .p8 file exists in the current directory
  if (!fs.existsSync(PRIVATE_KEY_FILE)) {
    throw new Error("File not found: " + PRIVATE_KEY_FILE);
  }

  const privateKey = fs.readFileSync(PRIVATE_KEY_FILE);
  
  // Timestamps for now and 6 months from now (180 days)
  const now = Math.floor(Date.now() / 1000);
  const exp = now + (180 * 24 * 60 * 60);

  const token = jwt.sign({}, privateKey, {
    algorithm: 'ES256',
    expiresIn: '180d',
    audience: 'https://appleid.apple.com',
    issuer: TEAM_ID,
    subject: SERVICES_ID,
    header: {
      kid: KEY_ID,
      alg: 'ES256'
    }
  });

  console.log("\n========================================================");
  console.log("SUCCESS! Copy the long string below into Supabase:");
  console.log("========================================================\n");
  console.log(token);
  console.log("\n========================================================\n");

} catch (err) {
  console.error("\n❌ ERROR:", err.message);
  console.log("Make sure your '" + PRIVATE_KEY_FILE + "' is in this folder.\n");
}
