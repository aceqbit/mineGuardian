// Twilio configuration
const twilio = require('twilio');

let twilioClient = null;

const getTwilioClient = () => {
  if (twilioClient) return twilioClient;

  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;

  if (!accountSid || accountSid.includes('placeholder') || accountSid === 'ACplaceholder00000000000000000000000') {
    console.warn('⚠️  Twilio: Using placeholder credentials — SMS disabled in dev mode');
    return null;
  }

  try {
    twilioClient = twilio(accountSid, authToken);
    console.log('✅ Twilio client initialized');
    return twilioClient;
  } catch (error) {
    console.error('❌ Twilio initialization error:', error.message);
    return null;
  }
};

module.exports = { getTwilioClient };
