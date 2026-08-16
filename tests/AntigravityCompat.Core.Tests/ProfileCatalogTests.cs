using System;
using System.IO;
using AntigravityCompat.Core;

namespace AntigravityCompat.Core.Tests;

public sealed class ProfileCatalogTests
{
    private const string MainPath = "resources/app/out/main.js";
    private const string WorkbenchPath = "resources/app/out/vs/workbench/workbench.desktop.main.js";
    private const string MainHash = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
    private const string WorkbenchHash = "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB";

    [Fact]
    public void UnknownHashProducesDiagnosticReadOnlySnapshot()
    {
        var catalog = new ProfileCatalog([CreateProfile(InstallationState.KnownSource)]);
        var snapshot = CreateSnapshot(MainHash, new string('C', 64));

        var result = catalog.Classify(snapshot);

        Assert.Equal(AccessMode.DiagnosticReadOnly, result.AccessMode);
        Assert.Equal(InstallationState.Unknown, result.State);
        Assert.Null(result.ProfileId);
    }

    [Fact]
    public void CompleteKnownSourceCombinationIsWritable()
    {
        var catalog = new ProfileCatalog([CreateProfile(InstallationState.KnownSource)]);

        var result = catalog.Classify(CreateSnapshot(MainHash, WorkbenchHash));

        Assert.Equal(AccessMode.SupportedReadWrite, result.AccessMode);
        Assert.Equal(InstallationState.KnownSource, result.State);
        Assert.Equal("legacy", result.ProfileId);
    }

    [Fact]
    public void CompleteKnownPatchedCombinationIsWritable()
    {
        var profile = CreateProfile(InstallationState.KnownPatched);
        var catalog = new ProfileCatalog([profile]);

        var result = catalog.Classify(CreateSnapshot(MainHash, WorkbenchHash));

        Assert.Equal(AccessMode.SupportedReadWrite, result.AccessMode);
        Assert.Equal(InstallationState.KnownPatched, result.State);
    }

    [Fact]
    public void SingleFileDriftProducesDiagnosticReadOnlySnapshot()
    {
        var catalog = new ProfileCatalog([CreateProfile(InstallationState.KnownSource)]);

        var result = catalog.Classify(CreateSnapshot(new string('C', 64), WorkbenchHash));

        Assert.Equal(AccessMode.DiagnosticReadOnly, result.AccessMode);
        Assert.Equal(InstallationState.Unknown, result.State);
    }

    [Fact]
    public void MissingRequiredFileProducesDiagnosticReadOnlySnapshot()
    {
        var catalog = new ProfileCatalog([CreateProfile(InstallationState.KnownSource)]);
        var snapshot = new InstallationSnapshot(
            "snapshot",
            AccessMode.DiagnosticReadOnly,
            InstallationState.Unknown,
            [new InstallationFileSnapshot(MainPath, MainHash)],
            "未分类",
            null);

        var result = catalog.Classify(snapshot);

        Assert.Equal(AccessMode.DiagnosticReadOnly, result.AccessMode);
        Assert.Contains("缺少", result.Reason, StringComparison.Ordinal);
    }

    [Fact]
    public void MultipleMatchingStatesProduceDiagnosticReadOnlySnapshot()
    {
        var first = CreateProfile(InstallationState.KnownSource, "first");
        var second = CreateProfile(InstallationState.KnownPatched, "second");
        var catalog = new ProfileCatalog([first, second]);

        var result = catalog.Classify(CreateSnapshot(MainHash, WorkbenchHash));

        Assert.Equal(AccessMode.DiagnosticReadOnly, result.AccessMode);
        Assert.Equal(InstallationState.Unknown, result.State);
        Assert.Contains("多个", result.Reason, StringComparison.Ordinal);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("../outside.js")]
    [InlineData("..\\outside.js")]
    [InlineData("/rooted.js")]
    [InlineData("\\rooted.js")]
    [InlineData("C:\\rooted.js")]
    [InlineData("C:drive-relative.js")]
    [InlineData("\\\\server\\share\\file.js")]
    [InlineData("\\\\?\\C:\\file.js")]
    [InlineData("file.js:stream")]
    [InlineData("CON")]
    [InlineData("safe/AUX.txt")]
    [InlineData("file.js.")]
    [InlineData("file.js ")]
    public void ProfileRejectsUnsafeRelativePath(string relativePath)
    {
        var profile = CreateProfileWithFiles([new FileSignature(relativePath, MainHash)]);

        Assert.Throws<InvalidDataException>(profile.Validate);
    }

    [Theory]
    [InlineData("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")]
    [InlineData("GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG")]
    [InlineData("aAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")]
    public void ProfileRejectsInvalidSha256(string sha256)
    {
        var profile = CreateProfileWithFiles([new FileSignature(MainPath, sha256)]);

        Assert.Throws<InvalidDataException>(profile.Validate);
    }

    [Fact]
    public void ProfileRejectsInvalidSha256CharacterAfterValidPrefix()
    {
        var sha256 = "A" + new string('G', 63);
        var profile = CreateProfileWithFiles([new FileSignature(MainPath, sha256)]);

        Assert.Throws<InvalidDataException>(profile.Validate);
    }

    [Fact]
    public void ProfileAcceptsLowercaseSha256()
    {
        var profile = CreateProfileWithFiles([new FileSignature(MainPath, MainHash.ToLowerInvariant())]);

        profile.Validate();
    }

    [Fact]
    public void ProfileRejectsCaseInsensitiveDuplicateRelativePaths()
    {
        var profile = CreateProfileWithFiles(
        [
            new FileSignature("resources/app/out/main.js", MainHash),
            new FileSignature("RESOURCES\\APP\\OUT\\MAIN.JS", WorkbenchHash),
        ]);

        Assert.Throws<InvalidDataException>(profile.Validate);
    }

    [Fact]
    public void ProfileRejectsDuplicateRequestedModelId()
    {
        var profile = CreateProfileWithFiles(
            [new FileSignature(MainPath, MainHash)],
            [
                new ModelRule(1264, CompatibilityState.Verified),
                new ModelRule(1264, CompatibilityState.LocalPreferenceBridge),
            ]);

        Assert.Throws<InvalidDataException>(profile.Validate);
    }

    [Fact]
    public void ProfileRejectsFileStatesWithDifferentPathSets()
    {
        var profile = new CompatibilityProfile(
            "legacy",
            [
                new FileState(
                    InstallationState.KnownSource,
                    [
                        new FileSignature(MainPath, MainHash),
                        new FileSignature(WorkbenchPath, WorkbenchHash),
                    ]),
                new FileState(
                    InstallationState.KnownPatched,
                    [new FileSignature(MainPath, MainHash)]),
            ],
            [new ModelRule(1264, CompatibilityState.Verified)]);

        Assert.Throws<InvalidDataException>(profile.Validate);
    }

    [Fact]
    public void ProfileRejectsDuplicateInstallationState()
    {
        var profile = new CompatibilityProfile(
            "legacy",
            [
                new FileState(
                    InstallationState.KnownSource,
                    [new FileSignature(MainPath, MainHash)]),
                new FileState(
                    InstallationState.KnownSource,
                    [new FileSignature(MainPath, WorkbenchHash)]),
            ],
            [new ModelRule(1264, CompatibilityState.Verified)]);

        Assert.Throws<InvalidDataException>(profile.Validate);
    }

    [Fact]
    public void ProfileRejectsEmptyModels()
    {
        var profile = CreateProfileWithFiles([new FileSignature(MainPath, MainHash)], []);

        Assert.Throws<InvalidDataException>(profile.Validate);
    }

    private static CompatibilityProfile CreateProfile(
        InstallationState state,
        string id = "legacy") =>
        new(
            id,
            [
                new FileState(
                    state,
                    [
                        new FileSignature(MainPath, MainHash),
                        new FileSignature(WorkbenchPath, WorkbenchHash),
                    ]),
            ],
            [new ModelRule(1264, CompatibilityState.Verified)]);

    private static CompatibilityProfile CreateProfileWithFiles(
        IReadOnlyList<FileSignature> files,
        IReadOnlyList<ModelRule>? models = null) =>
        new(
            "legacy",
            [new FileState(InstallationState.KnownSource, files)],
            models ?? [new ModelRule(1264, CompatibilityState.Verified)]);

    private static InstallationSnapshot CreateSnapshot(string mainHash, string workbenchHash) =>
        new(
            "snapshot",
            AccessMode.DiagnosticReadOnly,
            InstallationState.Unknown,
            [
                new InstallationFileSnapshot(MainPath, mainHash),
                new InstallationFileSnapshot(WorkbenchPath, workbenchHash),
            ],
            "未分类",
            null);
}
