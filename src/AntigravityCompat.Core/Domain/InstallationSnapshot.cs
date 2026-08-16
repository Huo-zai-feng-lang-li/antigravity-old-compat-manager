using System.Collections.Generic;

namespace AntigravityCompat.Core;

public enum AccessMode
{
    SupportedReadWrite,
    DiagnosticReadOnly,
}

public enum InstallationState
{
    KnownSource,
    KnownPatched,
    Unknown,
}

public sealed record InstallationFileSnapshot(
    string RelativePath,
    string Sha256);

public sealed record InstallationSnapshot(
    string SnapshotId,
    AccessMode AccessMode,
    InstallationState State,
    IReadOnlyList<InstallationFileSnapshot> Files,
    string Reason,
    string? ProfileId);
