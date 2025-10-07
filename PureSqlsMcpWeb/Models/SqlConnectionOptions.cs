namespace PureSqlsMcpWeb.Models;

/// <summary>
/// Налаштування підключення до SQL Server
/// </summary>
public class SqlConnectionOptions
{
    public string Server { get; set; } = "localhost";
    public string Database { get; set; } = "master";
    public bool IntegratedSecurity { get; set; } = true;
    public string? UserId { get; set; }
    public string? Password { get; set; }
    public bool TrustServerCertificate { get; set; } = true;
    public bool Encrypt { get; set; } = true;
    public int CommandTimeout { get; set; } = 180;
}
