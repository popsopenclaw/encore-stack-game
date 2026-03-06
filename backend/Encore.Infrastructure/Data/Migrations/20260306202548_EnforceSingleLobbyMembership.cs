using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Encore.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class EnforceSingleLobbyMembership : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_LobbyMembers_AccountId",
                table: "LobbyMembers",
                column: "AccountId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_LobbyMembers_AccountId",
                table: "LobbyMembers");
        }
    }
}
