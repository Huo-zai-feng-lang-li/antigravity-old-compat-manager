using System.Buffers.Binary;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using AntigravityCompat.Core;

namespace AntigravityCompat.Infrastructure.Windows;

public sealed class WindowsInstallationProbe : IInstallationProbe
{
    public async Task<InstallationSnapshot> ProbeAsync(
        string installationRoot,
        ProfileCatalog catalog,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(catalog);

        var root = NormalizeRoot(installationRoot);
        EnsureNotReparsePoint(root);
        var probedFiles = new List<ProbedFile>();

        foreach (var relativePath in catalog.RequiredRelativePaths)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var target = ResolveTarget(root, relativePath);
            EnsureNoReparsePoints(root, target);
            if (!File.Exists(target))
            {
                continue;
            }

            probedFiles.Add(await HashStableFileAsync(relativePath, target, cancellationToken));
        }

        var files = probedFiles
            .Select(file => new InstallationFileSnapshot(file.RelativePath, file.Sha256))
            .ToArray();
        var snapshot = new InstallationSnapshot(
            CreateSnapshotId(probedFiles),
            AccessMode.DiagnosticReadOnly,
            InstallationState.Unknown,
            files,
            "安装快照尚未分类。",
            null);
        return catalog.Classify(snapshot);
    }

    private static string NormalizeRoot(string installationRoot)
    {
        if (string.IsNullOrWhiteSpace(installationRoot))
        {
            throw new ArgumentException("安装根目录不能为空。", nameof(installationRoot));
        }

        var root = Path.TrimEndingDirectorySeparator(Path.GetFullPath(installationRoot));
        if (!Directory.Exists(root))
        {
            throw new DirectoryNotFoundException($"安装根目录不存在：{root}");
        }

        return root;
    }

    private static string ResolveTarget(string root, string relativePath)
    {
        var platformPath = relativePath.Replace('/', Path.DirectorySeparatorChar);
        var target = Path.GetFullPath(Path.Combine(root, platformPath));
        var rootPrefix = root.EndsWith(Path.DirectorySeparatorChar)
            ? root
            : root + Path.DirectorySeparatorChar;

        if (!target.StartsWith(rootPrefix, StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidDataException($"目标路径越出安装根目录：{relativePath}");
        }

        return target;
    }

    private static void EnsureNoReparsePoints(string root, string target)
    {
        EnsureNotReparsePoint(root);
        var relativePath = Path.GetRelativePath(root, target);
        var current = root;

        foreach (var segment in relativePath.Split(Path.DirectorySeparatorChar))
        {
            current = Path.Combine(current, segment);
            if (!File.Exists(current) && !Directory.Exists(current))
            {
                return;
            }

            EnsureNotReparsePoint(current);
        }
    }

    private static void EnsureNotReparsePoint(string path)
    {
        var attributes = File.GetAttributes(path);
        if ((attributes & FileAttributes.ReparsePoint) != 0)
        {
            throw new IOException($"拒绝读取重解析点：{path}");
        }
    }

    private static async Task<ProbedFile> HashStableFileAsync(
        string relativePath,
        string target,
        CancellationToken cancellationToken)
    {
        EnsureNotReparsePoint(target);
        var before = ReadVersion(target);
        byte[] hash;

        await using (var stream = new FileStream(
            target,
            FileMode.Open,
            FileAccess.Read,
            FileShare.Read,
            131072,
            FileOptions.Asynchronous | FileOptions.SequentialScan))
        {
            hash = await SHA256.HashDataAsync(stream, cancellationToken);
        }

        EnsureNotReparsePoint(target);
        var after = ReadVersion(target);
        if (before != after)
        {
            throw new IOException($"读取期间文件发生变化：{relativePath}");
        }

        return new ProbedFile(
            relativePath.Replace('\\', '/'),
            Convert.ToHexString(hash),
            before.Length);
    }

    private static FileVersion ReadVersion(string path)
    {
        var file = new FileInfo(path);
        file.Refresh();
        if (!file.Exists)
        {
            throw new FileNotFoundException("读取期间文件消失。", path);
        }

        return new FileVersion(file.Length, file.LastWriteTimeUtc);
    }

    private static string CreateSnapshotId(IEnumerable<ProbedFile> files)
    {
        using var hash = IncrementalHash.CreateHash(HashAlgorithmName.SHA256);
        foreach (var file in files.OrderBy(file => file.RelativePath, StringComparer.Ordinal))
        {
            AppendLengthPrefixed(hash, file.RelativePath);
            AppendLengthPrefixed(hash, file.Length.ToString(CultureInfo.InvariantCulture));
            AppendLengthPrefixed(hash, file.Sha256);
        }

        return Convert.ToHexString(hash.GetHashAndReset());
    }

    private static void AppendLengthPrefixed(IncrementalHash hash, string value)
    {
        var bytes = Encoding.UTF8.GetBytes(value);
        Span<byte> length = stackalloc byte[sizeof(int)];
        BinaryPrimitives.WriteInt32BigEndian(length, bytes.Length);
        hash.AppendData(length);
        hash.AppendData(bytes);
    }

    private sealed record ProbedFile(
        string RelativePath,
        string Sha256,
        long Length);

    private readonly record struct FileVersion(
        long Length,
        DateTime LastWriteTimeUtc);
}
