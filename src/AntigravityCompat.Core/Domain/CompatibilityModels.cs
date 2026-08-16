using System.Collections.Generic;
using System.Linq;

namespace AntigravityCompat.Core;

public enum CompatibilityState
{
    Verified,
    LocalPreferenceBridge,
    Quarantined,
}

public sealed record ModelDescriptor(
    string Label,
    int RequestedModelId,
    string Family,
    string Tier,
    string Fingerprint);

public sealed record ModelRule(
    int RequestedModelId,
    CompatibilityState State);

public sealed record ModelDecision(
    ModelDescriptor Model,
    CompatibilityState State,
    string Reason)
{
    public int RequestedModelId => Model.RequestedModelId;
}

public static class ModelPolicy
{
    public static ModelDecision Classify(
        ModelDescriptor model,
        IReadOnlyCollection<ModelRule> rules)
    {
        var matchingRules = rules
            .Where(candidate => candidate.RequestedModelId == model.RequestedModelId)
            .Take(2)
            .ToArray();

        return matchingRules.Length switch
        {
            0 => new(model, CompatibilityState.Quarantined, "未知模型默认隔离"),
            1 => new(model, matchingRules[0].State, "命中唯一规则"),
            _ => new(model, CompatibilityState.Quarantined, "同一模型 ID 存在重复规则，已隔离"),
        };
    }
}
