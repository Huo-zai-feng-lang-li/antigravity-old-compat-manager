using System.Text.Json;
using System.Text.Json.Serialization;
using AntigravityCompat.Core;

namespace AntigravityCompat.Infrastructure.Windows;

public sealed class JsonProfileRepository
{
    private static readonly JsonSerializerOptions SerializerOptions = CreateSerializerOptions();

    public async Task<IReadOnlyList<CompatibilityProfile>> LoadAsync(
        string profilesDirectory,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(profilesDirectory))
        {
            throw new ArgumentException("档案目录不能为空。", nameof(profilesDirectory));
        }

        var directory = Path.GetFullPath(profilesDirectory);
        if (!Directory.Exists(directory))
        {
            throw new DirectoryNotFoundException($"档案目录不存在：{directory}");
        }

        var profiles = new List<CompatibilityProfile>();
        var files = Directory
            .EnumerateFiles(directory, "*.json", SearchOption.TopDirectoryOnly)
            .OrderBy(path => path, StringComparer.Ordinal)
            .ToArray();

        foreach (var file in files)
        {
            profiles.Add(await LoadProfileAsync(file, cancellationToken));
        }

        _ = new ProfileCatalog(profiles);
        return profiles;
    }

    private static async Task<CompatibilityProfile> LoadProfileAsync(
        string path,
        CancellationToken cancellationToken)
    {
        try
        {
            await using var stream = new FileStream(
                path,
                FileMode.Open,
                FileAccess.Read,
                FileShare.Read,
                65536,
                FileOptions.Asynchronous | FileOptions.SequentialScan);
            var profile = await JsonSerializer.DeserializeAsync<CompatibilityProfile>(
                stream,
                SerializerOptions,
                cancellationToken);
            if (profile is null)
            {
                throw new InvalidDataException($"空适配档案：{Path.GetFileName(path)}");
            }

            profile.Validate();
            return profile;
        }
        catch (JsonException exception)
        {
            throw new InvalidDataException($"适配档案 JSON 无效：{Path.GetFileName(path)}", exception);
        }
    }

    private static JsonSerializerOptions CreateSerializerOptions()
    {
        var options = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            PropertyNameCaseInsensitive = false,
            UnmappedMemberHandling = JsonUnmappedMemberHandling.Disallow,
        };
        options.Converters.Add(new JsonStringEnumConverter(JsonNamingPolicy.CamelCase, false));
        return options;
    }
}
