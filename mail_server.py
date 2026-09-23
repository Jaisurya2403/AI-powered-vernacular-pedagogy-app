import json
import smtplib
from http.server import HTTPServer, BaseHTTPRequestHandler
from email.mime.text import MIMEText

SENDER_EMAIL = "alonewarrior123456@gmail.com"
SENDER_PASSWORD = "wpcemazdsvlfjpoc"

def send_email_via_smtp(recipient_email, subject, body):
    msg = MIMEText(body)
    msg['Subject'] = subject
    msg['From'] = f"Vernacular Pedagogy <{SENDER_EMAIL}>"
    msg['To'] = recipient_email

    try:
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(SENDER_EMAIL, SENDER_PASSWORD)
        server.sendmail(SENDER_EMAIL, [recipient_email], msg.as_string())
        server.quit()
        print(f"[SUCCESS] Email sent to {recipient_email}")
        return True, "Email sent successfully"
    except Exception as e:
        print(f"[ERROR] Failed to send email: {e}")
        return False, str(e)

class MailHandler(BaseHTTPRequestHandler):
    def _send_cors_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')

    def do_OPTIONS(self):
        self.send_response(200)
        self._send_cors_headers()
        self.end_headers()

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length) if content_length > 0 else b'{}'
        
        try:
            data = json.loads(post_data.decode('utf-8'))
        except Exception:
            data = {}

        if self.path == '/api/email/send-otp':
            recipient_email = data.get('recipientEmail', '')
            recipient_name = data.get('recipientName', 'User')
            otp_code = data.get('otpCode', '')
            
            subject = f"Vernacular Pedagogy - Email Verification OTP: {otp_code}"
            body = (
                f"Hello {recipient_name},\n\n"
                f"Your OTP code for Vernacular Pedagogy email verification is: {otp_code}\n\n"
                f"This code will expire in 10 minutes.\n\n"
                f"Thank you,\nVernacular Pedagogy Team"
            )
            success, msg = send_email_via_smtp(recipient_email, subject, body)
            
            self.send_response(200 if success else 500)
            self._send_cors_headers()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = {"success": success, "message": msg}
            self.wfile.write(json.dumps(response).encode('utf-8'))

        elif self.path == '/api/email/send-reset':
            recipient_email = data.get('recipientEmail', '')
            recipient_name = data.get('recipientName', 'Teacher')
            reset_code = data.get('resetCode', '')
            
            subject = f"Vernacular Pedagogy - Password Reset OTP: {reset_code}"
            body = (
                f"Hello {recipient_name},\n\n"
                f"Your Password Reset OTP code is: {reset_code}\n\n"
                f"Use this code to reset your password.\n\n"
                f"Thank you,\nVernacular Pedagogy Team"
            )
            success, msg = send_email_via_smtp(recipient_email, subject, body)
            
            self.send_response(200 if success else 500)
            self._send_cors_headers()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = {"success": success, "message": msg}
            self.wfile.write(json.dumps(response).encode('utf-8'))
        else:
            self.send_response(404)
            self._send_cors_headers()
            self.end_headers()

def run_server():
    server_address = ('', 8085)
    httpd = HTTPServer(server_address, MailHandler)
    print("Email Microservice Server listening on http://127.0.0.1:8085 ...")
    httpd.serve_forever()

if __name__ == '__main__':
    run_server()
