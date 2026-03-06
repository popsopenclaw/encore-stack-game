using Encore.Infrastructure.Services;
using Microsoft.Extensions.Configuration;

namespace Encore.Api.Tests;

public class PasswordHasherServiceTests
{
    private static PasswordHasherService CreateService()
        => new(new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["Auth:PasswordPepper"] = "unit-test-pepper"
        }).Build());

    [Fact]
    public void Hash_AndVerify_RoundTripSucceeds()
    {
        var service = CreateService();

        var credential = service.Hash("secret123");

        Assert.NotEmpty(credential.PasswordHash);
        Assert.NotEmpty(credential.Salt);
        Assert.True(service.Verify(credential, "secret123"));
        Assert.False(service.Verify(credential, "secret124"));
    }

    [Fact]
    public void Hash_WithShortPassword_Throws()
    {
        var service = CreateService();

        Assert.Throws<InvalidOperationException>(() => service.Hash("short"));
    }
}
