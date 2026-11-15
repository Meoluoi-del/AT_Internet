import smtplib
import logging
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.header import Header
from email.utils import formataddr
from config import Config

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')

def send_password_reset_email(to_email: str, username: str, reset_link: str, expires_minutes: int = 15) -> tuple:
    """
    Gửi email đặt lại mật khẩu thực tế qua SMTP (Google Gmail, Microsoft 365, hoặc Mail Server nội bộ).
    
    Hỗ trợ:
    - Cổng 465 (SSL mặc định của Gmail)
    - Cổng 587 (STARTTLS)
    - Định dạng MIME Multipart (HTML giao diện đẹp mắt + Plaintext dự phòng)
    
    Trả về: (success: bool, message: str)
    """
    # 1. Kiểm tra cấu hình SMTP
    if not Config.SMTP_ENABLED:
        logging.info("[MAILER] SMTP_ENABLED=False. Hệ thống sử dụng chế độ Sandbox mô phỏng.")
        return False, "SMTP_DISABLED"

    if not Config.SMTP_USER or not Config.SMTP_PASSWORD:
        logging.warning("[MAILER] Thiếu SMTP_USER hoặc SMTP_PASSWORD. Chuyển sang chế độ Sandbox mô phỏng.")
        return False, "SMTP_CREDENTIALS_MISSING"

    try:
        subject = f"[PTIT IT Security] Yêu cầu khôi phục mật khẩu tài khoản '{username}'"
        from_email = Config.SMTP_FROM_EMAIL or Config.SMTP_USER
        from_name = Config.SMTP_FROM_NAME or "PTIT NAC & Central IAM"

        msg = MIMEMultipart('alternative')
        msg['Subject'] = Header(subject, 'utf-8')
        msg['From'] = formataddr((str(Header(from_name, 'utf-8')), from_email))
        msg['To'] = to_email

        # 2. Nội dung dạng Văn bản thuần (Plain Text Fallback)
        text_content = f"""Xin chào {username},

Hệ thống Quản lý Truy cập Mạng & Xác thực Trung tâm (PTIT NAC & IAM) nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn (Email: {to_email}).

Vui lòng truy cập đường dẫn dưới đây để hoàn tất việc xác thực và đặt lại mật khẩu mới:
{reset_link}

LƯU Ý BẢO MẬT:
- Liên kết này có thời hạn hiệu lực trong {expires_minutes} phút và chỉ được sử dụng 1 lần duy nhất (One-Time Token).
- Tuyệt đối không chia sẻ liên kết này cho bất kỳ ai để bảo vệ quyền truy cập mạng và tài khoản SSO của bạn.
- Nếu bạn không yêu cầu khôi phục mật khẩu, vui lòng bỏ qua email này hoặc báo cáo cho Quản trị viên an ninh mạng.

Trân trọng,
Đội ngũ Quản trị An ninh Mạng Học viện (PTIT Security Team)
Học viện Công nghệ Bưu chính Viễn thông
"""

        # 3. Nội dung dạng HTML Chuyên nghiệp (HTML Rich Email)
        html_content = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Khôi phục mật khẩu PTIT NAC</title>
</head>
<body style="margin: 0; padding: 0; background-color: #0d0d11; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #f4f4f5;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #0d0d11; padding: 40px 10px;">
        <tr>
            <td align="center">
                <table role="presentation" width="100%" style="max-width: 580px; background-color: #16161c; border-radius: 20px; border: 1px solid #27272a; overflow: hidden; box-shadow: 0 20px 40px rgba(0,0,0,0.6);">
                    <!-- Header -->
                    <tr>
                        <td style="padding: 35px 35px 20px 35px; text-align: center; border-bottom: 1px solid #27272a; background: linear-gradient(180deg, #1f1f28 0%, #16161c 100%);">
                            <div style="display: inline-block; width: 60px; height: 60px; line-height: 60px; border-radius: 16px; background-color: #27272a; border: 1px solid #3f3f46; font-size: 26px; margin-bottom: 15px;">
                                🛡️
                            </div>
                            <h2 style="margin: 0; color: #ffffff; font-size: 20px; font-weight: 900; letter-spacing: 0.5px; text-transform: uppercase;">
                                HỌC VIỆN CÔNG NGHỆ BƯU CHÍNH VIỄN THÔNG
                            </h2>
                            <p style="margin: 6px 0 0 0; color: #a1a1aa; font-size: 12px; font-weight: 500;">
                                Trung tâm Kiểm soát Truy cập Mạng & Định danh Tập trung (NAC & IAM)
                            </p>
                        </td>
                    </tr>

                    <!-- Body Content -->
                    <tr>
                        <td style="padding: 35px 35px 25px 35px;">
                            <h3 style="margin: 0 0 16px 0; color: #f4f4f5; font-size: 17px; font-weight: 700;">
                                Yêu cầu khôi phục mật khẩu tài khoản
                            </h3>
                            <p style="margin: 0 0 16px 0; color: #d4d4d8; font-size: 14px; line-height: 1.6;">
                                Xin chào <strong style="color: #fbbf24;">{username}</strong>,
                            </p>
                            <p style="margin: 0 0 24px 0; color: #a1a1aa; font-size: 13.5px; line-height: 1.6;">
                                Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn liên kết với email <span style="color: #ffffff; font-family: monospace; background-color: #09090b; padding: 2px 6px; border-radius: 6px; border: 1px solid #27272a;">{to_email}</span>. Vui lòng bấm vào nút bên dưới để tiến hành xác thực danh tính và cập nhật mật khẩu mới.
                            </p>

                            <!-- CTA Button -->
                            <div style="text-align: center; margin: 30px 0;">
                                <a href="{reset_link}" target="_blank" style="display: inline-block; background: linear-gradient(135deg, #f59e0b 0%, #ea580c 100%); color: #000000; text-decoration: none; font-size: 14px; font-weight: 900; padding: 14px 34px; border-radius: 12px; text-transform: uppercase; letter-spacing: 0.5px; box-shadow: 0 8px 20px rgba(245, 158, 11, 0.35);">
                                    Xác Thực & Đổi Mật Khẩu
                                </a>
                            </div>

                            <!-- Expiry & Security Notice Box -->
                            <div style="background-color: #09090b; border: 1px solid #27272a; border-left: 4px solid #f59e0b; border-radius: 10px; padding: 16px; margin: 25px 0 15px 0;">
                                <p style="margin: 0; color: #e4e4e7; font-size: 12px; line-height: 1.5;">
                                    ⏱️ <strong>Thời hạn hiệu lực:</strong> Liên kết này có giá trị trong <strong>{expires_minutes} phút</strong> và chỉ sử dụng được <strong>1 lần duy nhất</strong> (One-Time Token) để bảo vệ tài khoản của bạn.
                                </p>
                            </div>

                            <p style="margin: 20px 0 0 0; color: #71717a; font-size: 12px; line-height: 1.5;">
                                Nếu nút trên không hoạt động, bạn có thể sao chép và dán trực tiếp đường dẫn sau vào trình duyệt:
                                <br>
                                <a href="{reset_link}" target="_blank" style="color: #60a5fa; word-break: break-all; font-size: 11.5px; font-family: monospace; text-decoration: underline;">
                                    {reset_link}
                                </a>
                            </p>
                        </td>
                    </tr>

                    <!-- Footer -->
                    <tr>
                        <td style="padding: 20px 35px 30px 35px; border-top: 1px solid #27272a; text-align: center; background-color: #121217;">
                            <p style="margin: 0; color: #71717a; font-size: 11px; line-height: 1.5;">
                                Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua thư này. Mật khẩu hiện tại của bạn vẫn an toàn tuyệt đối.<br>
                                © 2026 PTIT Central NAC & IAM Security Platform. RFC 2865 & IEEE 802.1X Standard.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
"""

        msg.attach(MIMEText(text_content, 'plain', 'utf-8'))
        msg.attach(MIMEText(html_content, 'html', 'utf-8'))

        # 4. Thực hiện kết nối gửi thư qua SMTP
        server = None
        if Config.SMTP_PORT == 465 or Config.SMTP_USE_SSL:
            server = smtplib.SMTP_SSL(Config.SMTP_SERVER, Config.SMTP_PORT, timeout=10)
        else:
            server = smtplib.SMTP(Config.SMTP_SERVER, Config.SMTP_PORT, timeout=10)
            if Config.SMTP_USE_TLS:
                server.starttls()

        server.login(Config.SMTP_USER, Config.SMTP_PASSWORD)
        server.sendmail(from_email, [to_email], msg.as_string())
        server.quit()

        logging.info(f"[MAILER] Gửi email khôi phục mật khẩu thành công tới: {to_email}")
        return True, "SENT_SUCCESSFULLY"

    except Exception as e:
        err_msg = str(e)
        logging.error(f"[MAILER] Lỗi khi gửi email qua SMTP: {err_msg}")
        return False, err_msg
