using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LibroSphere.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddUserIdRelationshipsForOrdersAndLibrary : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_UserBooks_UserEmail_BookId",
                table: "UserBooks");

            migrationBuilder.AddColumn<Guid>(
                name: "UserId",
                table: "UserBooks",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "UserId",
                table: "Orders",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.Sql("""
                UPDATE ub
                SET UserId = u.Id
                FROM UserBooks ub
                INNER JOIN Users u ON u.UserEmail = ub.UserEmail;
                """);

            migrationBuilder.Sql("""
                UPDATE o
                SET UserId = u.Id
                FROM Orders o
                INNER JOIN Users u ON u.UserEmail = o.BuyerEmail;
                """);

            migrationBuilder.Sql("""
                IF EXISTS (SELECT 1 FROM UserBooks WHERE UserId IS NULL)
                    THROW 51000, 'Cannot migrate UserBooks: one or more rows do not match an existing Users.UserEmail.', 1;
                """);

            migrationBuilder.Sql("""
                IF EXISTS (SELECT 1 FROM Orders WHERE UserId IS NULL)
                    THROW 51001, 'Cannot migrate Orders: one or more rows do not match an existing Users.UserEmail.', 1;
                """);

            migrationBuilder.AlterColumn<Guid>(
                name: "UserId",
                table: "UserBooks",
                type: "uniqueidentifier",
                nullable: false,
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier",
                oldNullable: true);

            migrationBuilder.AlterColumn<Guid>(
                name: "UserId",
                table: "Orders",
                type: "uniqueidentifier",
                nullable: false,
                oldClrType: typeof(Guid),
                oldType: "uniqueidentifier",
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserBooks_UserId_BookId",
                table: "UserBooks",
                columns: new[] { "UserId", "BookId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Orders_UserId",
                table: "Orders",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Orders_Users_UserId",
                table: "Orders",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_UserBooks_Users_UserId",
                table: "UserBooks",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Orders_Users_UserId",
                table: "Orders");

            migrationBuilder.DropForeignKey(
                name: "FK_UserBooks_Users_UserId",
                table: "UserBooks");

            migrationBuilder.DropIndex(
                name: "IX_UserBooks_UserId_BookId",
                table: "UserBooks");

            migrationBuilder.DropIndex(
                name: "IX_Orders_UserId",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "UserBooks");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "Orders");

            migrationBuilder.CreateIndex(
                name: "IX_UserBooks_UserEmail_BookId",
                table: "UserBooks",
                columns: new[] { "UserEmail", "BookId" },
                unique: true);
        }
    }
}
