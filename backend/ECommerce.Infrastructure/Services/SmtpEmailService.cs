namespace ECommerce.Infrastructure.Services;

using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ECommerce.Application.Interfaces;
using ECommerce.Infrastructure.Configuration;

public class SmtpEmailService : IEmailService
{
    private readonly SmtpSettings _settings;
    private readonly ILogger<SmtpEmailService> _logger;

    public SmtpEmailService(
        IOptions<SmtpSettings> options,
        ILogger<SmtpEmailService> logger)
    {
        _settings = options.Value;
        _logger = logger;
    }

    public async Task SendVerificationEmailAsync(string toEmail, string toName, string verificationToken, CancellationToken cancellationToken = default)
    {
        var cleanEmail = toEmail.Trim();
        var cleanName = toName.Trim();
        var baseUrl = string.IsNullOrWhiteSpace(_settings.BaseUrl) ? "http://100.101.117.77:5124" : _settings.BaseUrl.TrimEnd('/');

        var htmlBody = $@"<div style=""background-color: #121212; color: #ffffff; padding: 32px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; border-radius: 12px; text-align: center; max-width: 500px; margin: 0 auto;"">
  <h1 style=""color: #2196F3; margin-bottom: 8px;"">E-Commerce Móvil</h1>
  <h3 style=""color: #ffffff; margin-top: 0;"">¡Confirma tu cuenta para comenzar!</h3>
  <p style=""color: #b0b0b0; font-size: 15px; line-height: 1.5;"">
    Hola {cleanName}, gracias por registrarte. Para activar tu cuenta y acceder a nuestra tienda, por favor confirma tu dirección de correo electrónico haciendo clic en el siguiente botón:
  </p>
  <div style=""margin: 32px 0;"">
    <a href=""{baseUrl}/api/Auth/verify-email?token={verificationToken}"" 
       style=""background-color: #2196F3; color: #ffffff; padding: 14px 28px; text-decoration: none; font-size: 16px; font-weight: bold; border-radius: 8px; display: inline-block;"">
      Confirmar mi Cuenta
    </a>
  </div>
  <p style=""color: #757575; font-size: 12px; margin-top: 24px;"">
    Este enlace expirará en 24 horas. Si no realizaste esta solicitud, puedes ignorar este mensaje con total seguridad.
  </p>
</div>";

        try
        {
            using var client = new SmtpClient(_settings.Host, _settings.Port)
            {
                Credentials = new NetworkCredential(_settings.UserName, _settings.Password),
                EnableSsl = _settings.EnableSsl
            };

            using var message = new MailMessage
            {
                From = new MailAddress(_settings.SenderEmail, _settings.SenderName),
                Subject = "Confirma tu cuenta - E-Commerce Móvil",
                Body = htmlBody,
                IsBodyHtml = true
            };

            message.To.Add(cleanEmail);

            await client.SendMailAsync(message, cancellationToken);
            _logger.LogInformation("Correo de verificación enviado exitosamente vía Brevo SMTP a {Email}", cleanEmail);
        }
        catch (SmtpException ex)
        {
            _logger.LogError(ex, "Error SMTP al enviar correo de verificación vía Brevo a {Email} (StatusCode: {StatusCode})", cleanEmail, ex.StatusCode);
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error inesperado al enviar correo de verificación vía Brevo a {Email}", cleanEmail);
            throw;
        }
    }
}
