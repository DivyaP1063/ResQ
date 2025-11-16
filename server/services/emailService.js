const nodemailer = require('nodemailer');
const User = require('../models/User');

class EmailService {
  constructor() {
    this.transporter = this.createTransporter();
  }

  createTransporter() {
    // Configure transporter based on environment variables
    // You can use Gmail, SendGrid, or any other email service
    console.log('Email configuration check:');
    console.log('EMAIL_SERVICE:', process.env.EMAIL_SERVICE);
    console.log('EMAIL_USER:', process.env.EMAIL_USER);
    console.log('EMAIL_PASSWORD:', process.env.EMAIL_PASSWORD ? '***PRESENT***' : 'MISSING');
    console.log('EMAIL_FROM:', process.env.EMAIL_FROM);

    if (!process.env.EMAIL_USER || !process.env.EMAIL_PASSWORD) {
      throw new Error('Email credentials not found in environment variables');
    }

    return nodemailer.createTransport({
      service: process.env.EMAIL_SERVICE || 'gmail',
      auth: {
        user: process.env.EMAIL_USER, // Your email address
        pass: process.env.EMAIL_PASSWORD || process.env.EMAIL_PASS, // Your email password or app password
      },
      // Alternative configuration for custom SMTP
      // host: process.env.SMTP_HOST,
      // port: process.env.SMTP_PORT || 587,
      // secure: false, // true for 465, false for other ports
      // auth: {
      //   user: process.env.EMAIL_USER,
      //   pass: process.env.EMAIL_PASS,
      // },
    });
  }

  async sendEmergencyAlert(userId, emergencyData) {
    try {
      // Get user and their emergency contacts
      const user = await User.findById(userId);
      if (!user || !user.emergencyEmails || user.emergencyEmails.length === 0) {
        throw new Error('No emergency contacts found for user');
      }

      const { transcription, type, confidence, keywords, location, timestamp } = emergencyData;

      // Email template
      const subject = `🚨 EMERGENCY ALERT - ${user.firstName} ${user.lastName}`;
      
      const htmlContent = `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
            .container { max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
            .header { background-color: #dc2626; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; }
            .alert-badge { background-color: #fef2f2; border: 1px solid #fca5a5; color: #dc2626; padding: 10px; border-radius: 4px; margin: 15px 0; font-weight: bold; }
            .info-row { margin: 10px 0; padding: 8px; background-color: #f9fafb; border-left: 4px solid #3b82f6; }
            .emergency-details { background-color: #fff7ed; padding: 15px; border-radius: 6px; margin: 15px 0; }
            .footer { background-color: #f3f4f6; padding: 15px; text-align: center; font-size: 12px; color: #6b7280; }
            .urgent { color: #dc2626; font-weight: bold; }
            .timestamp { color: #6b7280; font-size: 14px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🚨 EMERGENCY ALERT</h1>
              <p>ResQ Crisis Response System</p>
            </div>
            
            <div class="content">
              <div class="alert-badge">
                URGENT: Emergency detected for ${user.firstName} ${user.lastName}
              </div>
              
              <div class="info-row">
                <strong>Person:</strong> ${user.firstName} ${user.lastName}
              </div>
              
              <div class="info-row">
                <strong>Email:</strong> ${user.email}
              </div>
              
              <div class="info-row">
                <strong>Emergency Type:</strong> <span class="urgent">${type || 'General Emergency'}</span>
              </div>
              
              <div class="info-row">
                <strong>Detection Confidence:</strong> ${Math.round(confidence * 100)}%
              </div>
              
              <div class="info-row">
                <strong>Time:</strong> <span class="timestamp">${new Date(timestamp).toLocaleString()}</span>
              </div>
              
              ${location ? `
                <div class="info-row">
                  <strong>Location:</strong> ${location}
                </div>
              ` : ''}
              
              <div class="emergency-details">
                <h3>Transcribed Audio:</h3>
                <p><em>"${transcription}"</em></p>
                
                ${keywords && keywords.length > 0 ? `
                  <p><strong>Detected Keywords:</strong> ${keywords.join(', ')}</p>
                ` : ''}
              </div>
              
              <div style="background-color: #fef3c7; padding: 15px; border-radius: 6px; margin-top: 20px;">
                <h3 style="color: #92400e; margin: 0 0 10px 0;">⚡ Immediate Action Required</h3>
                <ul style="color: #92400e; margin: 0; padding-left: 20px;">
                  <li>Try calling ${user.firstName} at their registered phone number</li>
                  <li>If no response, consider contacting local emergency services</li>
                  <li>This is an automated alert from ResQ Crisis Response App</li>
                </ul>
              </div>
            </div>
            
            <div class="footer">
              <p>This email was automatically sent by ResQ Crisis Response System</p>
              <p>Report ID: ${emergencyData.recordingId || 'N/A'}</p>
              <p>If this is a false alarm, please disregard this message</p>
            </div>
          </div>
        </body>
        </html>
      `;

      const textContent = `
🚨 EMERGENCY ALERT - ResQ Crisis Response System

URGENT: Emergency detected for ${user.firstName} ${user.lastName}

Person: ${user.firstName} ${user.lastName}
Email: ${user.email}
Emergency Type: ${type || 'General Emergency'}
Detection Confidence: ${Math.round(confidence * 100)}%
Time: ${new Date(timestamp).toLocaleString()}
${location ? `Location: ${location}` : ''}

Transcribed Audio: "${transcription}"
${keywords && keywords.length > 0 ? `Detected Keywords: ${keywords.join(', ')}` : ''}

⚡ IMMEDIATE ACTION REQUIRED:
- Try calling ${user.firstName} at their registered phone number
- If no response, consider contacting local emergency services
- This is an automated alert from ResQ Crisis Response App

Report ID: ${emergencyData.recordingId || 'N/A'}
If this is a false alarm, please disregard this message.
      `;

      // Send email to all emergency contacts
      const emailPromises = user.emergencyEmails.map(async (email) => {
        const mailOptions = {
          from: process.env.EMAIL_USER || 'noreply@resq-app.com',
          to: email,
          subject: subject,
          text: textContent,
          html: htmlContent,
          priority: 'high',
          headers: {
            'X-Priority': '1 (Highest)',
            'X-MSMail-Priority': 'High',
            'Importance': 'high'
          }
        };

        return this.transporter.sendMail(mailOptions);
      });

      // Send all emails concurrently
      const results = await Promise.allSettled(emailPromises);
      
      // Log results
      const successful = results.filter(result => result.status === 'fulfilled').length;
      const failed = results.filter(result => result.status === 'rejected').length;
      
      console.log(`Emergency alert sent: ${successful} successful, ${failed} failed`);
      
      // Log failed emails for debugging
      results.forEach((result, index) => {
        if (result.status === 'rejected') {
          console.error(`Failed to send to ${user.emergencyEmails[index]}:`, result.reason);
        }
      });

      return {
        success: true,
        sent: successful,
        failed: failed,
        totalRecipients: user.emergencyEmails.length
      };

    } catch (error) {
      console.error('Error sending emergency alert:', error);
      throw error;
    }
  }

  async testConnection() {
    try {
      await this.transporter.verify();
      console.log('Email service connection verified successfully');
      return true;
    } catch (error) {
      console.error('Email service connection failed:', error);
      return false;
    }
  }

  async sendTestEmail(testEmail) {
    try {
      const transporter = this.createTransporter();
      
      const mailOptions = {
        from: `${process.env.EMAIL_FROM_NAME} <${process.env.EMAIL_FROM}>`,
        to: testEmail,
        subject: 'ResQ Email Test',
        html: `
          <h2>Email Configuration Test</h2>
          <p>If you receive this email, your SMTP configuration is working correctly!</p>
          <p>Timestamp: ${new Date().toISOString()}</p>
        `
      };

      console.log('Sending test email to:', testEmail);
      console.log('Email config:', {
        service: process.env.EMAIL_SERVICE,
        user: process.env.EMAIL_USER,
        from: process.env.EMAIL_FROM
      });

      const result = await transporter.sendMail(mailOptions);
      console.log('Test email sent successfully:', result.messageId);
      
      return result;
    } catch (error) {
      console.error('Error sending test email:', error);
      throw error;
    }
  }
}

module.exports = new EmailService();