using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Encore.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddLobbyActiveSession : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ActiveSessionId",
                table: "Lobbies",
                type: "character varying(64)",
                maxLength: 64,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ActiveSessionId",
                table: "Lobbies");
        }
    }
}
