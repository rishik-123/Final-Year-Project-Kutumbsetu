import os
import sys
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Load .env manually to avoid extra pip dependency
def load_env():
    env_path = os.path.join(os.path.dirname(__file__), '.env')
    if os.path.exists(env_path):
        with open(env_path, 'r') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                parts = line.split('=', 1)
                if len(parts) == 2:
                    key = parts[0].strip()
                    val = parts[1].strip()
                    if val.startswith(('"', "'")) and val.endswith(('"', "'")):
                        val = val[1:-1]
                    os.environ[key] = val

load_env()

def send_otp_email(recipient_email, otp, name="User"):
    smtp_host = os.environ.get('SMTP_HOST', 'smtp.gmail.com')
    smtp_port = int(os.environ.get('SMTP_PORT', '465'))
    smtp_secure = os.environ.get('SMTP_SECURE', 'true').lower() == 'true' or smtp_port == 465
    smtp_user = os.environ.get('SMTP_USER')
    smtp_pass = os.environ.get('SMTP_PASS')

    if not smtp_user or not smtp_pass:
        print("[Python Error] SMTP_USER or SMTP_PASS not set in environment.")
        sys.exit(1)

    # Build the HTML content
    html_content = f"""
    <div style="font-family: 'Poppins', 'Inter', sans-serif; max-width: 600px; margin: 0 auto; background-color: #ffffff; border: 1px solid #e2e8f0; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);">
        <!-- Saffron Top Banner -->
        <div style="background: linear-gradient(135deg, #e67e22, #1b4f72); padding: 24px; text-align: center; color: #ffffff;">
            <h1 style="margin: 0; font-size: 28px; font-weight: bold; letter-spacing: 1px;">KutumbSetu</h1>
            <p style="margin: 4px 0 0 0; font-size: 14px; opacity: 0.9;">कुटुम्बસેતુ • Family & Community Network</p>
        </div>
        
        <!-- Email Body -->
        <div style="padding: 32px; color: #1a202c; line-height: 1.6;">
            <h2 style="margin-top: 0; font-size: 20px; font-weight: 700; color: #1b4f72;">Hello {name},</h2>
            <p style="font-size: 15px; margin-bottom: 24px;">Please use the secure One-Time Password (OTP) below to complete your authentication. This code is valid for <strong>5 minutes</strong>.</p>
            
            <!-- OTP Display Box -->
            <div style="text-align: center; margin: 32px 0;">
                <div style="display: inline-block; padding: 16px 40px; background-color: #fff8e7; border: 2px dashed #e67e22; border-radius: 12px;">
                    <span style="font-size: 36px; font-weight: 800; letter-spacing: 6px; color: #e67e22; font-family: monospace;">{otp}</span>
                </div>
            </div>
            
            <p style="font-size: 13px; color: #718096; margin-bottom: 24px;"><em>Security Warning: If you did not request this OTP, please ignore this email or contact support if you suspect unauthorized access. Do not share this OTP code with anyone.</em></p>
            
            <hr style="border: 0; border-top: 1px solid #edf2f7; margin: 24px 0;" />
            
            <p style="font-size: 12px; color: #a0aec0; text-align: center; margin: 0;">This is an automated system message. Please do not reply directly to this email.</p>
        </div>
        
        <!-- Footer -->
        <div style="background-color: #f7fafc; padding: 16px; text-align: center; font-size: 11px; color: #718096; border-top: 1px solid #edf2f7;">
            © 2026 KutumbSetu Community Management System. All rights reserved.
        </div>
    </div>
    """

    msg = MIMEMultipart('alternative')
    msg['Subject'] = 'KutumbSetu - Your Email Verification OTP'
    msg['From'] = f"KutumbSetu Portal <{smtp_user}>"
    msg['To'] = recipient_email

    msg.attach(MIMEText(html_content, 'html'))

    try:
        # Connect to Gmail SMTP using SSL/TLS
        if smtp_secure:
            server = smtplib.SMTP_SSL(smtp_host, smtp_port, timeout=10)
        else:
            server = smtplib.SMTP(smtp_host, smtp_port, timeout=10)
            server.starttls()
        
        server.login(smtp_user, smtp_pass)
        server.sendmail(smtp_user, recipient_email, msg.as_string())
        server.quit()
        print(f"[Python Success] Email successfully sent to {recipient_email}")
    except Exception as e:
        print(f"[Python Error] SMTP delivery failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python send_otp.py <email> <otp> [name]")
        sys.exit(1)
    
    email_arg = sys.argv[1]
    otp_arg = sys.argv[2]
    name_arg = sys.argv[3] if len(sys.argv) > 3 else "User"

    send_otp_email(email_arg, otp_arg, name_arg)
