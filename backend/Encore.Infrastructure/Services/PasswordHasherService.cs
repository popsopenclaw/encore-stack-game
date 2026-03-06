using System.Security.Cryptography;
using System.Text;
using Encore.Domain.Models;
using Microsoft.Extensions.Configuration;

namespace Encore.Infrastructure.Services;

public class PasswordHasherService(IConfiguration configuration)
{
    public const int CurrentHashVersion = 1;
    private const int SaltSize = 32;
    private const int HashSize = 32;
    private const int Iterations = 210_000;

    public LocalAccountCredential Hash(string password)
    {
        var normalizedPassword = NormalizePasswordForStorage(password);
        var salt = RandomNumberGenerator.GetBytes(SaltSize);

        return new LocalAccountCredential
        {
            PasswordHash = DeriveHash(normalizedPassword, salt),
            Salt = salt,
            HashVersion = CurrentHashVersion
        };
    }

    public bool Verify(LocalAccountCredential credential, string password)
    {
        var normalizedPassword = NormalizePasswordForVerification(password);
        var computed = DeriveHash(normalizedPassword, credential.Salt);
        return CryptographicOperations.FixedTimeEquals(computed, credential.PasswordHash);
    }

    private byte[] DeriveHash(string password, byte[] salt)
    {
        var pepper = configuration["Auth:PasswordPepper"];
        if (string.IsNullOrWhiteSpace(pepper))
            throw new InvalidOperationException("Missing Auth:PasswordPepper");

        var bytes = Encoding.UTF8.GetBytes(password + pepper);
        return Rfc2898DeriveBytes.Pbkdf2(bytes, salt, Iterations, HashAlgorithmName.SHA512, HashSize);
    }

    private static string NormalizePasswordForStorage(string password)
    {
        var value = password.Trim();
        if (value.Length < 8)
            throw new InvalidOperationException("Password must be at least 8 characters.");

        return value;
    }

    private static string NormalizePasswordForVerification(string password)
        => password.Trim();
}
