const std = @import("std");

pub const TokenType = enum { IDENTIFIER, BINARY_OPERATOR, SEPARATOR, INT_LITERAL, FLOAT_LITERAL, CHAR_LITERAL, STRING_LITERAL, BOOLEAN_LITERAL, NULL_LITERAL, OPEN_PAREN, CLOSE_PAREN, OPEN_BRACKET, CLOSE_BRACKET, OPEN_CURLY_BRACE, CLOSE_CURLY_BRACE, WHITE_SPACE, LINE_BREAK };

pub const Token = struct {
    value: []const u8,
    _type: TokenType,

    const Self = @This();

    pub fn init(value: []const u8, _type: TokenType) Self {
        return .{ .value = value, ._type = _type };
    }

    pub fn println(self: *Self, writer: std.fs.File.Writer) !void {
        try writer.print("Token{{ .value = \"", .{});
        for (self.value) |char| {
            if (char == '\n') {
                try writer.writeAll("\\n");
            } else {
                try writer.print("{c}", .{char});
            }
        }
        try writer.print("\", ._type = {} }}\n", .{self._type});
    }
};
