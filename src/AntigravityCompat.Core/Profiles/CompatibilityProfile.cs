using System;
using System.Collections.Generic;
using System.IO;

namespace AntigravityCompat.Core;

public sealed record FileSignature(
    string RelativePath,
    string Sha256);

public sealed record FileState(
    InstallationState State,
    IReadOnlyList<FileSignature> Files);

public sealed record CompatibilityProfile(
    string Id,
    IReadOnlyList<FileState> FileStates,
    IReadOnlyList<ModelRule> Models)
{
    private static readonly HashSet<string> ReservedNames = new(StringComparer.OrdinalIgnoreCase)
    {
        "CON",
        "PRN",
        "AUX",
        "NUL",
        "CLOCK$",
        "CONIN$",
        "CONOUT$",
        "COM1",
        "COM2",
        "COM3",
        "COM4",
        "COM5",
        "COM6",
        "COM7",
        "COM8",
        "COM9",
        "LPT1",
        "LPT2",
        "LPT3",
        "LPT4",
        "LPT5",
        "LPT6",
        "LPT7",
        "LPT8",
        "LPT9",
    };

    public void Validate()
    {
        if (string.IsNullOrWhiteSpace(Id))
        {
            throw new InvalidDataException("适配档案 ID 不能为空。");
        }

        if (FileStates is null || FileStates.Count == 0)
        {
            throw new InvalidDataException($"适配档案 {Id} 未声明文件状态。");
        }

        if (Models is null || Models.Count == 0)
        {
            throw new InvalidDataException($"适配档案 {Id} 必须声明模型规则。");
        }

        ValidateFileStates();
        ValidateModels();
    }

    internal static string NormalizeRelativePath(string relativePath) =>
        relativePath.Replace('\\', '/');

    private void ValidateFileStates()
    {
        var states = new HashSet<InstallationState>();
        HashSet<string>? expectedPaths = null;

        foreach (var fileState in FileStates)
        {
            ValidateFileState(fileState);
            if (!states.Add(fileState.State))
            {
                throw new InvalidDataException($"适配档案 {Id} 包含重复安装状态：{fileState.State}。");
            }

            var paths = CreatePathSet(fileState.Files);
            expectedPaths ??= paths;
            if (!expectedPaths.SetEquals(paths))
            {
                throw new InvalidDataException($"适配档案 {Id} 的文件状态必须声明相同路径集合。");
            }
        }
    }

    private static HashSet<string> CreatePathSet(IReadOnlyList<FileSignature> signatures)
    {
        var paths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var signature in signatures)
        {
            paths.Add(NormalizeRelativePath(signature.RelativePath));
        }

        return paths;
    }

    private void ValidateFileState(FileState fileState)
    {
        if (fileState is null || fileState.Files is null || fileState.Files.Count == 0)
        {
            throw new InvalidDataException($"适配档案 {Id} 包含空文件状态。");
        }

        if (fileState.State == InstallationState.Unknown)
        {
            throw new InvalidDataException($"适配档案 {Id} 不能声明未知文件状态。");
        }

        var paths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var signature in fileState.Files)
        {
            ValidateSignature(signature);
            if (!paths.Add(NormalizeRelativePath(signature.RelativePath)))
            {
                throw new InvalidDataException($"适配档案 {Id} 包含重复相对路径。");
            }
        }
    }

    private void ValidateSignature(FileSignature signature)
    {
        if (signature is null || !IsSafeRelativePath(signature.RelativePath))
        {
            throw new InvalidDataException($"适配档案 {Id} 包含非法相对路径。");
        }

        if (!IsSha256(signature.Sha256))
        {
            throw new InvalidDataException($"适配档案 {Id} 包含非法 SHA-256。");
        }
    }

    private void ValidateModels()
    {
        var modelIds = new HashSet<int>();
        foreach (var model in Models)
        {
            if (!modelIds.Add(model.RequestedModelId))
            {
                throw new InvalidDataException($"适配档案 {Id} 包含重复模型 ID：{model.RequestedModelId}。");
            }
        }
    }

    private static bool IsSafeRelativePath(string? relativePath)
    {
        if (string.IsNullOrWhiteSpace(relativePath) || IsRootedOrSpecial(relativePath))
        {
            return false;
        }

        var segments = relativePath.Split(['/', '\\'], StringSplitOptions.None);
        foreach (var segment in segments)
        {
            if (!IsSafeSegment(segment))
            {
                return false;
            }
        }

        return true;
    }

    private static bool IsRootedOrSpecial(string relativePath) =>
        relativePath[0] is '/' or '\\'
        || relativePath.Contains(':', StringComparison.Ordinal)
        || relativePath.IndexOfAny(['<', '>', '"', '|', '?', '*']) >= 0;

    private static bool IsSafeSegment(string segment)
    {
        if (segment.Length == 0 || segment is "." or "..")
        {
            return false;
        }

        if (segment[^1] is '.' or ' ' || ContainsControlCharacter(segment))
        {
            return false;
        }

        var extensionIndex = segment.IndexOf('.', StringComparison.Ordinal);
        var baseName = extensionIndex < 0 ? segment : segment[..extensionIndex];
        return !ReservedNames.Contains(baseName);
    }

    private static bool ContainsControlCharacter(string value)
    {
        foreach (var character in value)
        {
            if (character < ' ')
            {
                return true;
            }
        }

        return false;
    }

    private static bool IsSha256(string? sha256)
    {
        if (sha256 is null || sha256.Length != 64)
        {
            return false;
        }

        var containsUppercase = false;
        var containsLowercase = false;
        foreach (var character in sha256)
        {
            if (!IsAsciiHex(character, ref containsUppercase, ref containsLowercase))
            {
                return false;
            }
        }

        return !(containsUppercase && containsLowercase);
    }

    private static bool IsAsciiHex(
        char character,
        ref bool containsUppercase,
        ref bool containsLowercase)
    {
        if (character is >= '0' and <= '9')
        {
            return true;
        }

        if (character is >= 'A' and <= 'F')
        {
            containsUppercase = true;
            return true;
        }

        if (character is >= 'a' and <= 'f')
        {
            containsLowercase = true;
            return true;
        }

        return false;
    }
}
