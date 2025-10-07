using PlanSqlsMcp;

// ??????? ?????????? ?????????? ?????
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
            Console.WriteLine("PlanSqlsMcp - MCP ?????? ??? ????????? SQL Server Execution Plans");
            Console.WriteLine();
            Console.WriteLine("????????????:");
            Console.WriteLine("  PlanSqlsMcp [?????]");
            Console.WriteLine();
            Console.WriteLine("?????:");
            Console.WriteLine("  -s, --server <server>      SQL Server (?? ?????????????: localhost)");
            Console.WriteLine("  -d, --database <database>  ???? ????? (?? ?????????????: master)");
            Console.WriteLine("  -u, --user <user>          ?????????? SQL Server (???????????? SQL Auth)");
            Console.WriteLine("  -p, --password <password>  ?????? (???????????????? ? --user)");
            Console.WriteLine("  -h, --help                 ???????? ?? ???????");
            Console.WriteLine();
            Console.WriteLine("???????????:");
            Console.WriteLine("  ShowEstimatedExecutionPlan - ??????? estimated execution plan ??? SQL ??????");
            return 0;
    }
}

try
{
    var serverInstance = new PlanMcpServer(server, database, integratedSecurity, userId, password);
    await serverInstance.RunAsync();
    return 0;
}
catch (Exception ex)
{
    Console.Error.WriteLine($"? ???????? ???????: {ex.Message}");
    Console.Error.WriteLine(ex.StackTrace);
    return 1;
}
