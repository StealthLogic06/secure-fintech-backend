using Npgsql;

var connString =
    "Host=localhost;Port=5432;Username=fintech;Password=fintech;Database=fintech_db";

using var conn = new NpgsqlConnection(connString);
conn.Open();

var sql = """
SELECT id, status, account_balance
FROM users;
""";

using var cmd = new NpgsqlCommand(sql, conn);
using var reader = cmd.ExecuteReader();

while (reader.Read())
{
    Console.WriteLine(
        $"User {reader.GetGuid(0)} | Status={reader.GetString(1)} | Balance={reader.GetInt64(2)}"
    );
}

Console.WriteLine("Read-only DB verification successful");
