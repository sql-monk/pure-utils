using Microsoft.AspNetCore.Mvc;
using System.Reflection;

namespace PureSqlsMcpWeb.Controllers;

/// <summary>
/// Контролер для загальної інформації про API
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class InfoController : ControllerBase
{
    private readonly IConfiguration _configuration;

    public InfoController(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    /// <summary>
    /// Отримати інформацію про API
    /// </summary>
    [HttpGet]
    public IActionResult GetInfo()
    {
        var version = Assembly.GetExecutingAssembly()
            .GetCustomAttribute<AssemblyInformationalVersionAttribute>()?
            .InformationalVersion ?? "1.0.0";

        return Ok(new
        {
            name = "PureSqlsMcp Web API",
            version = version,
            description = "Web API для роботи з SQL Server через MCP протокол",
            documentation = "/swagger",
            endpoints = new
            {
                health = "/health",
                toolsList = "/api/tools/list",
                callTool = "/api/tools/call",
                connectionTest = "/api/tools/connection-test"
            },
            integrations = new[]
            {
                "GPT Custom Actions",
                "Claude API",
                "REST clients",
                "Web applications"
            }
        });
    }

    /// <summary>
    /// Отримати конфігурацію підключення (без чутливих даних)
    /// </summary>
    [HttpGet("connection")]
    public IActionResult GetConnectionInfo()
    {
        var server = _configuration["SqlConnection:Server"];
        var database = _configuration["SqlConnection:Database"];
        var integratedSecurity = _configuration.GetValue<bool>("SqlConnection:IntegratedSecurity");

        return Ok(new
        {
            server = server,
            database = database,
            authenticationType = integratedSecurity ? "Windows Authentication" : "SQL Server Authentication",
            encrypted = _configuration.GetValue<bool>("SqlConnection:Encrypt"),
            trustServerCertificate = _configuration.GetValue<bool>("SqlConnection:TrustServerCertificate")
        });
    }
}
