using PureSqlsMcp;

// Парсинг аргументів командного рядка
var cmdArgs = Environment.GetCommandLineArgs().Skip(1).ToArray();

string server = "localhost";
string database = "master";
bool integratedSecurity = true;
string? userId = null;
string? password = null;

for (int i = 0; i < cmdArgs.Length; i++)
{
    switch (cmdArgs[i].ToLower())
    {
        case "--server" or "-s":
            if (i + 1 < cmdArgs.Length) server = cmdArgs[++i];
            break;
        case "--database" or "-d":
            if (i + 1 < cmdArgs.Length) database = cmdArgs[++i];
            break;
        case "--user" or "-u":
            if (i + 1 < cmdArgs.Length)
            {
                userId = cmdArgs[++i];
                integratedSecurity = false;
            }
            break;
        case "--password" or "-p":
            if (i + 1 < cmdArgs.Length) password = cmdArgs[++i];
            break;
        case "--help" or "-h":
            Console.WriteLine("MCP SQL Server Dynamic - Model Context Protocol сервер для SQL Server 2022");

            return 0;
    }
}

try
{
    var server_instance = new PureMcpServer(server, database, integratedSecurity, userId, password);
    await server_instance.RunAsync();
    return 0;
}
catch (Exception ex)
{
    Console.Error.WriteLine($"❌ Критична помилка: {ex.Message}");
    Console.Error.WriteLine(ex.StackTrace);
    return 1;
}
