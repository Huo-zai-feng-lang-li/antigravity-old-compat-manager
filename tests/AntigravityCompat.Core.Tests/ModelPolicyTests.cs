using AntigravityCompat.Core;

namespace AntigravityCompat.Core.Tests;

public sealed class ModelPolicyTests
{
    [Fact]
    public void RequestedModelIdComesFromModel()
    {
        var model = new ModelDescriptor("Gemini 3.6 Flash", 1264, "Gemini 3.6", "High", "fp");

        var decision = new ModelDecision(model, CompatibilityState.Verified, "test");

        Assert.Equal(model.RequestedModelId, decision.RequestedModelId);
    }

    [Fact]
    public void UnknownModelIsQuarantined()
    {
        var model = new ModelDescriptor("Future Model", 9001, "Future", "High", "fp");

        var decision = ModelPolicy.Classify(model, []);

        Assert.Equal(CompatibilityState.Quarantined, decision.State);
    }

    [Fact]
    public void UnknownModelIsQuarantinedWhenRulesAreNotEmpty()
    {
        var model = new ModelDescriptor("Future Model", 9001, "Future", "High", "fp");
        var rules = new[]
        {
            new ModelRule(1264, CompatibilityState.LocalPreferenceBridge),
            new ModelRule(1265, CompatibilityState.LocalPreferenceBridge),
        };

        var decision = ModelPolicy.Classify(model, rules);

        Assert.Equal(CompatibilityState.Quarantined, decision.State);
        Assert.Equal(model.RequestedModelId, decision.RequestedModelId);
    }

    [Fact]
    public void MatchingRuleIsSelectedFromMultipleRules()
    {
        var model = new ModelDescriptor("Gemini 3.6 Pro", 1265, "Gemini 3.6", "High", "fp");
        var rules = new[]
        {
            new ModelRule(1264, CompatibilityState.Verified),
            new ModelRule(1265, CompatibilityState.LocalPreferenceBridge),
            new ModelRule(1266, CompatibilityState.Quarantined),
        };

        var decision = ModelPolicy.Classify(model, rules);

        Assert.Equal(CompatibilityState.LocalPreferenceBridge, decision.State);
        Assert.Equal(model.RequestedModelId, decision.RequestedModelId);
    }

    [Fact]
    public void DuplicateRulesQuarantineModelInsteadOfThrowing()
    {
        var model = new ModelDescriptor("Gemini 3.6 Flash", 1264, "Gemini 3.6", "High", "fp");
        var rules = new[]
        {
            new ModelRule(1264, CompatibilityState.Verified),
            new ModelRule(1264, CompatibilityState.LocalPreferenceBridge),
        };

        var decision = ModelPolicy.Classify(model, rules);

        Assert.Equal(CompatibilityState.Quarantined, decision.State);
        Assert.Equal(model.RequestedModelId, decision.RequestedModelId);
        Assert.Equal("同一模型 ID 存在重复规则，已隔离", decision.Reason);
    }

    [Theory]
    [InlineData(1264)]
    [InlineData(1265)]
    public void Gemini36HighAndMediumUseLocalPreferenceBridgeAndKeepRealRequestedModel(int requestedModelId)
    {
        var model = new ModelDescriptor(
            "Gemini 3.6 Flash",
            requestedModelId,
            "Gemini 3.6",
            "High",
            "fp");
        var rules = new[]
        {
            new ModelRule(requestedModelId, CompatibilityState.LocalPreferenceBridge),
        };

        var decision = ModelPolicy.Classify(model, rules);

        Assert.Equal(CompatibilityState.LocalPreferenceBridge, decision.State);
        Assert.Equal(requestedModelId, decision.RequestedModelId);
    }

    [Fact]
    public void Gemini36LowIsQuarantined()
    {
        var model = new ModelDescriptor(
            "Gemini 3.6 Flash",
            1266,
            "Gemini 3.6",
            "Low",
            "fp");

        var decision = ModelPolicy.Classify(model, []);

        Assert.Equal(CompatibilityState.Quarantined, decision.State);
        Assert.Equal(1266, decision.RequestedModelId);
    }
}
