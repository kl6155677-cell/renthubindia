const { Resend } = require('resend');

const resend = new Resend(process.env.RESEND_API_KEY);

// We need a verified sender domain in Resend.
// For testing without a domain, Resend provides a testing email: 'onboarding@resend.dev'
// In production, change this to your verified domain e.g., 'RentHubIndia <noreply@renthubindia.com>'
const FROM_EMAIL = process.env.NODE_ENV === 'production' && process.env.EMAIL_FROM 
  ? process.env.EMAIL_FROM 
  : 'RentHubIndia <onboarding@resend.dev>';

const sendOtpEmail = async (to, code) => {
  try {
    const data = await resend.emails.send({
      from: FROM_EMAIL,
      to,
      subject: `${process.env.APP_NAME || 'RentHubIndia'} - Password Reset OTP`,
      html: `
        <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e5e7eb; border-radius: 12px;">
          <h2 style="color: #111827;">Password Reset</h2>
          <p style="color: #4b5563; font-size: 16px;">Your One-Time Password (OTP) for resetting your password is:</p>
          <div style="background-color: #f3f4f6; padding: 20px; text-align: center; border-radius: 8px; margin: 24px 0;">
            <h1 style="color: #0f766e; letter-spacing: 4px; font-size: 32px; margin: 0;">${code}</h1>
          </div>
          <p style="color: #6b7280; font-size: 14px;">This code will expire in 10 minutes. If you did not request this, please ignore this email.</p>
          <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 24px 0;" />
          <p style="color: #9ca3af; font-size: 12px;">Sent by ${process.env.APP_NAME || 'RentHubIndia'}</p>
        </div>
      `,
    });

    if (data.error) {
      console.error(`❌ FAILED to send OTP email to ${to}:`, data.error);
      throw new Error(data.error.message);
    }

    console.log(`📧 OTP email sent successfully to ${to} (ID: ${data.data?.id})`);
    return data;
  } catch (error) {
    console.error(`❌ FAILED to send OTP email to ${to}:`, error);
    throw new Error('Failed to send verification email. Please check your Resend configuration.');
  }
};

const sendNotificationEmail = async (to, subject, body) => {
  try {
    const data = await resend.emails.send({
      from: FROM_EMAIL,
      to,
      subject,
      html: `<div>${body}</div>`,
    });

    if (data.error) {
      console.error(`❌ FAILED to send notification email to ${to}:`, data.error);
      throw new Error(data.error.message);
    }

    console.log(`📧 Notification email sent successfully to ${to} (ID: ${data.data?.id})`);
    return data;
  } catch (error) {
    console.error(`❌ FAILED to send notification email to ${to}:`, error);
    throw new Error('Failed to send notification email. Please check your Resend configuration.');
  }
};

module.exports = {
  resend,
  sendOtpEmail,
  sendNotificationEmail,
};