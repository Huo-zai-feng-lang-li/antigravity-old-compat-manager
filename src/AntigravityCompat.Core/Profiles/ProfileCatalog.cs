using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace AntigravityCompat.Core;

public sealed class ProfileCatalog
{
    private readonly CompatibilityProfile[] _profiles;

    public ProfileCatalog(IEnumerable<CompatibilityProfile> profiles)
    {
        ArgumentNullException.ThrowIfNull(profiles);

        _profiles = profiles.ToArray();
        ValidateProfiles(_profiles);
        RequiredRelativePaths = _profiles
            .SelectMany(profile => profile.FileStates)
            .SelectMany(fileState => fileState.Files)
            .Select(signature => CompatibilityProfile.NormalizeRelativePath(signature.RelativePath))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(relativePath => relativePath, StringComparer.Ordinal)
            .ToArray();
    }

    public IReadOnlyList<CompatibilityProfile> Profiles => _profiles;

    public IReadOnlyList<string> RequiredRelativePaths { get; }

    public InstallationSnapshot Classify(InstallationSnapshot snapshot)
    {
        ArgumentNullException.ThrowIfNull(snapshot);

        if (!TryCreateFileMap(snapshot.Files, out var files))
        {
            return AsReadOnly(snapshot, "安装快照包含重复文件路径，只允许诊断。");
        }

        var matches = FindMatches(files).Take(2).ToArray();
        if (matches.Length == 1)
        {
            return AsSupported(snapshot, matches[0]);
        }

        if (matches.Length > 1)
        {
            return AsReadOnly(snapshot, "多个适配档案同时匹配，只允许诊断。");
        }

        var reason = RequiredRelativePaths.Any(path => !files.ContainsKey(path))
            ? "缺少适配档案所需文件，只允许诊断。"
            : "未知安装哈希，只允许诊断。";
        return AsReadOnly(snapshot, reason);
    }

    private static void ValidateProfiles(IReadOnlyList<CompatibilityProfile> profiles)
    {
        var ids = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var profile in profiles)
        {
            if (profile is null)
            {
                throw new InvalidDataException("适配档案集合包含空项。");
            }

            profile.Validate();
            if (!ids.Add(profile.Id))
            {
                throw new InvalidDataException($"适配档案 ID 重复：{profile.Id}。");
            }
        }
    }

    private IEnumerable<ProfileMatch> FindMatches(
        IReadOnlyDictionary<string, InstallationFileSnapshot> files)
    {
        foreach (var profile in _profiles)
        {
            foreach (var fileState in profile.FileStates)
            {
                if (Matches(fileState, files))
                {
                    yield return new ProfileMatch(profile.Id, fileState.State);
                }
            }
        }
    }

    private static bool Matches(
        FileState fileState,
        IReadOnlyDictionary<string, InstallationFileSnapshot> files)
    {
        foreach (var signature in fileState.Files)
        {
            var path = CompatibilityProfile.NormalizeRelativePath(signature.RelativePath);
            if (!files.TryGetValue(path, out var actual)
                || !string.Equals(actual.Sha256, signature.Sha256, StringComparison.OrdinalIgnoreCase))
            {
                return false;
            }
        }

        return true;
    }

    private static bool TryCreateFileMap(
        IReadOnlyList<InstallationFileSnapshot>? snapshots,
        out Dictionary<string, InstallationFileSnapshot> files)
    {
        files = new Dictionary<string, InstallationFileSnapshot>(StringComparer.OrdinalIgnoreCase);
        if (snapshots is null)
        {
            return false;
        }

        foreach (var snapshot in snapshots)
        {
            var path = CompatibilityProfile.NormalizeRelativePath(snapshot.RelativePath);
            if (!files.TryAdd(path, snapshot))
            {
                return false;
            }
        }

        return true;
    }

    private static InstallationSnapshot AsSupported(
        InstallationSnapshot snapshot,
        ProfileMatch match) =>
        snapshot with
        {
            AccessMode = AccessMode.SupportedReadWrite,
            State = match.State,
            Reason = "命中唯一适配档案。",
            ProfileId = match.ProfileId,
        };

    private static InstallationSnapshot AsReadOnly(
        InstallationSnapshot snapshot,
        string reason) =>
        snapshot with
        {
            AccessMode = AccessMode.DiagnosticReadOnly,
            State = InstallationState.Unknown,
            Reason = reason,
            ProfileId = null,
        };

    private sealed record ProfileMatch(
        string ProfileId,
        InstallationState State);
}
