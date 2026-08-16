using System.Security.Cryptography;
using System.Text;
using AntigravityCompat.Core;
using AntigravityCompat.Infrastructure.Windows;

namespace AntigravityCompat.Infrastructure.Windows.Tests;

public sealed class WindowsInstallationProbeTests
{
    private const string RelativePath = "resources/app/out/main.js";

    [Fact]
    public async Task ProbeHashesRealFileAndProducesRootIndependentSnapshotId()
    {
        using var first = new TempDirectory();
        using var second = new TempDirectory();
        first.WriteFile(RelativePath, "stable-content");
        second.WriteFile(RelativePath, "stable-content");
        var expectedHash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes("stable-content")));
        var catalog = CreateCatalog(expectedHash);
        var probe = new WindowsInstallationProbe();

        var firstSnapshot = await probe.ProbeAsync(first.Path, catalog);
        var secondSnapshot = await probe.ProbeAsync(second.Path + Path.DirectorySeparatorChar, catalog);

        var file = Assert.Single(firstSnapshot.Files);
        Assert.Equal(expectedHash, file.Sha256);
        Assert.Equal(RelativePath, file.RelativePath);
        Assert.Equal(firstSnapshot.SnapshotId, secondSnapshot.SnapshotId);
        Assert.Equal(AccessMode.SupportedReadWrite, firstSnapshot.AccessMode);
    }

    [Fact]
    public async Task ProbeRejectsReparsePointInTargetParentChain()
    {
        using var install = new TempDirectory();
        using var external = new TempDirectory();
        external.WriteFile("main.js", "stable-content");
        var link = Path.Combine(install.Path, "resources");
        Directory.CreateSymbolicLink(link, external.Path);
        var expectedHash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes("stable-content")));
        var profile = new CompatibilityProfile(
            "legacy",
            [new FileState(InstallationState.KnownSource, [new FileSignature("resources/main.js", expectedHash)])],
            [new ModelRule(1264, CompatibilityState.Verified)]);
        var probe = new WindowsInstallationProbe();

        await Assert.ThrowsAsync<IOException>(() => probe.ProbeAsync(install.Path, new ProfileCatalog([profile])));
    }

    [Fact]
    public async Task JsonRepositoryLoadsCamelCaseProfileAndValidatesIt()
    {
        using var profiles = new TempDirectory();
        profiles.WriteFile(
            "legacy.json",
            """
            {
              "id": "legacy",
              "fileStates": [
                {
                  "state": "knownSource",
                  "files": [
                    {
                      "relativePath": "resources/app/out/main.js",
                      "sha256": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                    }
                  ]
                }
              ],
              "models": [
                { "requestedModelId": 1264, "state": "localPreferenceBridge" }
              ]
            }
            """);
        var repository = new JsonProfileRepository();

        var loaded = await repository.LoadAsync(profiles.Path);

        var profile = Assert.Single(loaded);
        Assert.Equal("legacy", profile.Id);
        Assert.Equal(1264, Assert.Single(profile.Models).RequestedModelId);
    }

    private static ProfileCatalog CreateCatalog(string sha256)
    {
        var profile = new CompatibilityProfile(
            "legacy",
            [new FileState(InstallationState.KnownSource, [new FileSignature(RelativePath, sha256)])],
            [new ModelRule(1264, CompatibilityState.Verified)]);
        return new ProfileCatalog([profile]);
    }

    private sealed class TempDirectory : IDisposable
    {
        public TempDirectory()
        {
            Path = System.IO.Path.Combine(System.IO.Path.GetTempPath(), $"antigravity-compat-{Guid.NewGuid():N}");
            Directory.CreateDirectory(Path);
        }

        public string Path { get; }

        public void WriteFile(string relativePath, string content)
        {
            var target = System.IO.Path.Combine(Path, relativePath.Replace('/', System.IO.Path.DirectorySeparatorChar));
            Directory.CreateDirectory(System.IO.Path.GetDirectoryName(target)!);
            File.WriteAllText(target, content, new UTF8Encoding(false));
        }

        public void Dispose()
        {
            Directory.Delete(Path, true);
        }
    }
}
