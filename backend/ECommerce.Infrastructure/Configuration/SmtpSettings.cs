namespace ECommerce.Infrastructure.Configuration;

public class SmtpSettings
{
    public const string SectionName = "SmtpSettings";
    public string Host { get; set; } = "smtp-relay.brevo.com";
    public int Port { get; set; } = 587;
    public bool EnableSsl { get; set; } = true;
    public string UserName { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string SenderEmail { get; set; } = "stalinpalate4@gmail.com";
    public string SenderName { get; set; } = "E-Commerce Móvil";
    public string BaseUrl { get; set; } = "http://100.101.117.77:5124";
}
