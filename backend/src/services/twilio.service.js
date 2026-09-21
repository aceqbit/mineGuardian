// Twilio SMS Service
const { getTwilioClient } = require('../config/twilio');
const AuditLog = require('../models/AuditLog.model');

/**
 * Send SMS to supervisor when hazard is reported
 */
const sendHazardReportSMS = async ({ hazardReport, supervisorPhone, supervisorName }) => {
  const client = getTwilioClient();

  if (!client) {
    console.log('[Twilio DEV] SMS would be sent to:', supervisorPhone);
    console.log('[Twilio DEV] Message: Hazard reported by', hazardReport.reporterName);
    return { success: false, reason: 'dev_mode' };
  }

  const gpsLink = `https://maps.google.com/?q=${hazardReport.gpsLocation.latitude},${hazardReport.gpsLocation.longitude}`;
  const message = `🚨 MINE GUARDIAN ALERT
Zone: ${hazardReport.zone}
Reporter: ${hazardReport.reporterName}
Hazard: ${hazardReport.description.substring(0, 100)}
Severity: ${hazardReport.severity.toUpperCase()}
GPS: ${gpsLink}
Time: ${new Date().toLocaleTimeString('en-IN', { timeZone: 'Asia/Kolkata' })} IST
Open MineGuardian app to respond.`;

  try {
    const result = await client.messages.create({
      body: message,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: supervisorPhone,
    });

    console.log(`✅ Hazard SMS sent to ${supervisorName}: ${result.sid}`);

    return {
      success: true,
      messageSid: result.sid,
      to: supervisorPhone,
    };
  } catch (error) {
    console.error('❌ Twilio SMS error:', error.message);
    return { success: false, error: error.message };
  }
};

/**
 * Send SOS alert SMS (Phase 2 foundation)
 */
const sendSOSAlertSMS = async ({ minerName, zone, gpsLocation, supervisorPhone }) => {
  const client = getTwilioClient();

  if (!client) {
    console.log('[Twilio DEV] SOS SMS would be sent to:', supervisorPhone);
    return { success: false, reason: 'dev_mode' };
  }

  const gpsLink = `https://maps.google.com/?q=${gpsLocation.latitude},${gpsLocation.longitude}`;
  const message = `🆘 SOS EMERGENCY — MINE GUARDIAN
Miner: ${minerName}
Zone: ${zone}
GPS: ${gpsLink}
Time: ${new Date().toLocaleTimeString('en-IN', { timeZone: 'Asia/Kolkata' })} IST
IMMEDIATE RESPONSE REQUIRED. Call miner now.`;

  try {
    const result = await client.messages.create({
      body: message,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: supervisorPhone,
    });

    return { success: true, messageSid: result.sid };
  } catch (error) {
    console.error('❌ SOS Twilio SMS error:', error.message);
    return { success: false, error: error.message };
  }
};

module.exports = { sendHazardReportSMS, sendSOSAlertSMS };
