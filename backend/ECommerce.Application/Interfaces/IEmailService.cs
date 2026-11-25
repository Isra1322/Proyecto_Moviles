namespace ECommerce.Application.Interfaces;

public interface IEmailService
{
    Task SendVerificationEmailAsync(string toEmail, string toName, string verificationToken, CancellationToken cancellationToken = default);
}
