using System.Text;

namespace LibroSphere.Infrastructure.Configuration;

public static class DotEnvLoader
{
    public static void LoadFromCurrentDirectory()
    {
        foreach (var filePath in FindEnvFiles())
        {
            LoadFile(filePath);
        }
    }

    private static IEnumerable<string> FindEnvFiles()
    {
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var basePath in new[] { Directory.GetCurrentDirectory(), AppContext.BaseDirectory })
        {
            var directory = new DirectoryInfo(basePath);
            while (directory is not null)
            {
                foreach (var fileName in new[] { ".env", ".env.local" })
                {
                    var candidate = Path.Combine(directory.FullName, fileName);
                    if (File.Exists(candidate) && seen.Add(candidate))
                    {
                        yield return candidate;
                    }
                }

                directory = directory.Parent;
            }
        }
    }

    private static void LoadFile(string path)
    {
        foreach (var rawLine in File.ReadAllLines(path, Encoding.UTF8))
        {
            var line = rawLine.Trim();
            if (string.IsNullOrWhiteSpace(line) || line.StartsWith('#'))
            {
                continue;
            }

            var separatorIndex = line.IndexOf('=');
            if (separatorIndex <= 0)
            {
                continue;
            }

            var key = line[..separatorIndex].Trim();
            var value = line[(separatorIndex + 1)..].Trim();

            if (!string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable(key)))
            {
                continue;
            }

            if (value.StartsWith('"') && value.EndsWith('"') && value.Length >= 2)
            {
                value = value[1..^1];
            }

            Environment.SetEnvironmentVariable(key, value);
        }
    }
}
