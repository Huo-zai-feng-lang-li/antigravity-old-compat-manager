using System.Threading;
using System.Threading.Tasks;

namespace AntigravityCompat.Core;

public interface IInstallationProbe
{
    Task<InstallationSnapshot> ProbeAsync(
        string installationRoot,
        ProfileCatalog catalog,
        CancellationToken cancellationToken = default);
}
