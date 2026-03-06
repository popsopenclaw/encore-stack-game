using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Encore.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class MultiProviderAuth : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:PostgresExtension:citext", ",,");

            migrationBuilder.Sql("""
                WITH ranked AS (
                    SELECT
                        "Id",
                        "Email",
                        ROW_NUMBER() OVER (
                            PARTITION BY lower(coalesce(nullif(trim("Email"), ''), ''))
                            ORDER BY "CreatedAt", "Id"
                        ) AS rn
                    FROM "Accounts"
                )
                UPDATE "Accounts" AS a
                SET "Email" = CASE
                    WHEN coalesce(nullif(trim(a."Email"), ''), '') = '' OR position('@' in trim(a."Email")) = 0
                        THEN 'account-' || replace(a."Id"::text, '-', '') || '@placeholder.invalid'
                    WHEN ranked.rn = 1
                        THEN lower(trim(a."Email"))
                    ELSE 'account-' || replace(a."Id"::text, '-', '') || '@placeholder.invalid'
                END
                FROM ranked
                WHERE ranked."Id" = a."Id";
                """);

            migrationBuilder.AlterColumn<string>(
                name: "Username",
                table: "Accounts",
                type: "citext",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<string>(
                name: "Email",
                table: "Accounts",
                type: "citext",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            migrationBuilder.CreateTable(
                name: "AccountLinks",
                columns: table => new
                {
                    Provider = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    ExternalId = table.Column<string>(type: "text", nullable: false),
                    AccountId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AccountLinks", x => new { x.Provider, x.ExternalId });
                    table.ForeignKey(
                        name: "FK_AccountLinks_Accounts_AccountId",
                        column: x => x.AccountId,
                        principalTable: "Accounts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "LocalAccountCredentials",
                columns: table => new
                {
                    AccountId = table.Column<Guid>(type: "uuid", nullable: false),
                    PasswordHash = table.Column<byte[]>(type: "bytea", nullable: false),
                    Salt = table.Column<byte[]>(type: "bytea", nullable: false),
                    HashVersion = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LocalAccountCredentials", x => x.AccountId);
                    table.ForeignKey(
                        name: "FK_LocalAccountCredentials_Accounts_AccountId",
                        column: x => x.AccountId,
                        principalTable: "Accounts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Accounts_Email",
                table: "Accounts",
                column: "Email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_AccountLinks_AccountId",
                table: "AccountLinks",
                column: "AccountId");

            migrationBuilder.CreateIndex(
                name: "IX_AccountLinks_Provider_AccountId",
                table: "AccountLinks",
                columns: new[] { "Provider", "AccountId" },
                unique: true);

            migrationBuilder.Sql("""
                INSERT INTO "AccountLinks" ("Provider", "ExternalId", "AccountId", "CreatedAt")
                SELECT 'github', "GitHubId"::text, "Id", "CreatedAt"
                FROM "Accounts"
                WHERE "GitHubId" <> 0;
                """);

            migrationBuilder.DropIndex(
                name: "IX_Accounts_GitHubId",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "GitHubId",
                table: "Accounts");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Accounts_Email",
                table: "Accounts");

            migrationBuilder.AddColumn<long>(
                name: "GitHubId",
                table: "Accounts",
                type: "bigint",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.Sql("""
                UPDATE "Accounts" AS a
                SET "GitHubId" = links."ExternalId"::bigint
                FROM "AccountLinks" AS links
                WHERE links."Provider" = 'github' AND links."AccountId" = a."Id";
                """);

            migrationBuilder.DropTable(
                name: "AccountLinks");

            migrationBuilder.DropTable(
                name: "LocalAccountCredentials");

            migrationBuilder.AlterDatabase()
                .OldAnnotation("Npgsql:PostgresExtension:citext", ",,");

            migrationBuilder.AlterColumn<string>(
                name: "Username",
                table: "Accounts",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "citext");

            migrationBuilder.AlterColumn<string>(
                name: "Email",
                table: "Accounts",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "citext");

            migrationBuilder.CreateIndex(
                name: "IX_Accounts_GitHubId",
                table: "Accounts",
                column: "GitHubId",
                unique: true);
        }
    }
}
