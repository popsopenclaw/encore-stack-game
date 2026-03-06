using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Encore.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddAccountPlayerName : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "NormalizedPlayerName",
                table: "Accounts",
                type: "character varying(24)",
                maxLength: 24,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PlayerName",
                table: "Accounts",
                type: "character varying(24)",
                maxLength: 24,
                nullable: true);

            migrationBuilder.Sql("""
                UPDATE "Accounts"
                SET "PlayerName" = 'player-' || substring(md5("Id"::text) from 1 for 8),
                    "NormalizedPlayerName" = upper('player-' || substring(md5("Id"::text) from 1 for 8))
                WHERE "PlayerName" IS NULL OR "NormalizedPlayerName" IS NULL;
                """);

            migrationBuilder.AlterColumn<string>(
                name: "PlayerName",
                table: "Accounts",
                type: "character varying(24)",
                maxLength: 24,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "character varying(24)",
                oldMaxLength: 24,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "NormalizedPlayerName",
                table: "Accounts",
                type: "character varying(24)",
                maxLength: 24,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "character varying(24)",
                oldMaxLength: 24,
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Accounts_NormalizedPlayerName",
                table: "Accounts",
                column: "NormalizedPlayerName",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Accounts_NormalizedPlayerName",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "NormalizedPlayerName",
                table: "Accounts");

            migrationBuilder.DropColumn(
                name: "PlayerName",
                table: "Accounts");
        }
    }
}
