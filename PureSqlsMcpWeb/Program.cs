using PureSqlsMcpWeb.Services;
using PureSqlsMcpWeb.Models;

var builder = WebApplication.CreateBuilder(args);

// Configure Kestrel to use ports from appsettings.json
builder.WebHost.ConfigureKestrel((context, serverOptions) =>
{
    var kestrelSection = context.Configuration.GetSection("Kestrel");
    serverOptions.Configure(kestrelSection);
});

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() 
    { 
        Title = "PureSqlsMcp Web API", 
        Version = "v1",
        Description = "Web API для роботи з SQL Server через MCP протокол для GPT та інших чатів"
    });
});

// Configure SQL connection from appsettings
builder.Services.Configure<SqlConnectionOptions>(
    builder.Configuration.GetSection("SqlConnection"));

builder.Services.AddSingleton<SqlToolsService>();

// Add CORS for GPT and other chat services
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowAll");

app.UseAuthorization();

app.MapControllers();

// Health check endpoint
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }));

// Log startup information
var kestrelUrl = builder.Configuration.GetSection("Kestrel:Endpoints:Http:Url").Value ?? "http://localhost:5000";
app.Logger.LogInformation("PureSqlsMcp Web API started at {Url}", kestrelUrl);
app.Logger.LogInformation("Swagger UI available at {Url}/swagger", kestrelUrl);

app.Run();
