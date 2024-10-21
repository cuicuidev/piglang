const std = @import("std");
const token = @import("token.zig");
const ascii = @import("ascii.zig");

const StringSlice = struct { slice: []const u8, start_idx: usize };

const LexerState = enum { NEW_TOKEN, COMPLETE_TOKEN, IDENTIFIER, INT_LITERAL, FLOAT_LITERAL, CHAR_LITERAL, STRING_LITERAL, OPERATOR, OPEN_PAREN, CLOSE_PAREN, OPEN_BRACKET, CLOSE_BRACKET, OPEN_CURLY_BRACE, CLOSE_CURLY_BRACE, WHITE_SPACE, LINE_BREAK };

pub const LexerErr = error{UnrecognizedCharacter};

pub const Lexer = struct {
    source: []const u8,
    pos: usize,
    max_idx: usize,
    state: LexerState,
    byte_buffer: StringSlice,
    tokens: std.ArrayList(token.Token),
    allocator: *std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: *std.mem.Allocator, source: []const u8) Self {
        const tokens = std.ArrayList(token.Token).init(allocator.*);
        const byte_buffer: StringSlice = StringSlice{ .slice = source[0..0], .start_idx = 0 };
        return .{ .source = source, .pos = 0, .max_idx = source.len, .state = LexerState.NEW_TOKEN, .byte_buffer = byte_buffer, .tokens = tokens, .allocator = allocator };
    }

    pub fn deinit(self: *Self) void {
        self.tokens.deinit();
    }

    pub fn printTokens(self: *Self, writer: std.fs.File.Writer) !void {
        for (self.tokens.items) |*t| {
            try t.*.println(writer);
        }
    }

    pub fn tokenize(self: *Self) !void {
        while (self.pos < self.max_idx) {
            try self._next();
        }
    }

    fn _next(self: *Self) !void {
        const char = self.source[self.pos];
        var next_char: ?u8 = undefined;
        if (self.pos < self.source.len - 1) {
            next_char = self.source[self.pos + 1];
        } else {
            next_char = null;
        }
        switch (self.state) {
            LexerState.NEW_TOKEN => {
                if (ascii.isAsciiLetterOrUnderscore(char)) {
                    self.state = LexerState.IDENTIFIER;
                    return;
                }

                if (ascii.isDigit(char)) {
                    self.state = LexerState.INT_LITERAL;
                    return;
                }

                if (char == '\'') {
                    self.state = LexerState.CHAR_LITERAL;
                    return;
                }

                if (char == '"') {
                    self.state = LexerState.STRING_LITERAL;
                    return;
                }

                if (ascii.isSymbol(char)) {
                    self.state = LexerState.OPERATOR;
                    return;
                }

                if (char == '(') {
                    self.state = LexerState.OPEN_PAREN;
                    return;
                }

                if (char == ')') {
                    self.state = LexerState.CLOSE_PAREN;
                    return;
                }

                if (char == '[') {
                    self.state = LexerState.OPEN_BRACKET;
                    return;
                }

                if (char == ']') {
                    self.state = LexerState.CLOSE_BRACKET;
                    return;
                }

                if (char == '{') {
                    self.state = LexerState.OPEN_CURLY_BRACE;
                    return;
                }

                if (char == '}') {
                    self.state = LexerState.CLOSE_CURLY_BRACE;
                    return;
                }

                if (ascii.isWhiteSpace(char)) {
                    self.state = LexerState.WHITE_SPACE;
                    return;
                }

                if (char == '\n') {
                    self.state = LexerState.LINE_BREAK;
                    return;
                }
            },
            LexerState.COMPLETE_TOKEN => {
                self.byte_buffer = StringSlice{ .slice = self.source[self.pos..self.pos], .start_idx = self.pos };
                self.state = LexerState.NEW_TOKEN;
            },
            LexerState.IDENTIFIER => {
                self._increment();

                if (next_char) |c| {
                    if (!ascii.isAsciiLetterOrUnderscore(c) and !ascii.isDigit(c)) {
                        const t = token.Token{ .value = self.byte_buffer.slice, ._type = token.TokenType.IDENTIFIER };
                        try self.tokens.append(t);
                        self.state = LexerState.COMPLETE_TOKEN;
                    }
                } else {
                    const t = token.Token{ .value = self.byte_buffer.slice, ._type = token.TokenType.IDENTIFIER };
                    try self.tokens.append(t);
                    self.state = LexerState.COMPLETE_TOKEN;
                }
            },
            LexerState.INT_LITERAL => {
                self._increment();

                if (next_char) |c| {
                    if (ascii.isWhiteSpace(c) or ascii.isSymbol(c) or c == '\n') {
                        const t = token.Token{ .value = self.byte_buffer.slice, ._type = token.TokenType.INT_LITERAL };
                        try self.tokens.append(t);
                        self.state = LexerState.COMPLETE_TOKEN;
                    }
                    if (c == '.' or c == 'e' or c == 'E') {
                        self.state = LexerState.FLOAT_LITERAL;
                    }
                } else {
                    const t = token.Token{ .value = self.byte_buffer.slice, ._type = token.TokenType.INT_LITERAL };
                    try self.tokens.append(t);
                    self.state = LexerState.COMPLETE_TOKEN;
                }
            },
            LexerState.FLOAT_LITERAL => {
                self._increment();

                if (next_char) |c| {
                    if (ascii.isWhiteSpace(c) or ascii.isSymbol(c) or c == '\n') {
                        const t = token.Token{ .value = self.byte_buffer.slice, ._type = token.TokenType.FLOAT_LITERAL };
                        try self.tokens.append(t);
                        self.state = LexerState.COMPLETE_TOKEN;
                    }
                } else {
                    const t = token.Token{ .value = self.byte_buffer.slice, ._type = token.TokenType.FLOAT_LITERAL };
                    try self.tokens.append(t);
                    self.state = LexerState.COMPLETE_TOKEN;
                }
            },
            LexerState.CHAR_LITERAL => {
                self._increment();

                const c = next_char.?;

                if (char != '\\') {
                    if (c == '\'') {
                        self.pos += 1;
                        self.byte_buffer = StringSlice{ .slice = self.source[self.byte_buffer.start_idx..self.pos], .start_idx = self.byte_buffer.start_idx };

                        const t = token.Token{ .value = self.byte_buffer.slice, ._type = token.TokenType.CHAR_LITERAL };
                        try self.tokens.append(t);
                        self.state = LexerState.COMPLETE_TOKEN;
                    }
                }
            },
            LexerState.STRING_LITERAL => {
                self._increment();

                const c = next_char.?;

                if (char != '\\') {
                    if (c == '"') {
                        self._increment();

                        const t = token.Token{ .value = self.byte_buffer.slice, ._type = token.TokenType.STRING_LITERAL };
                        try self.tokens.append(t);
                        self.state = LexerState.COMPLETE_TOKEN;
                    }
                }
            },
            LexerState.OPERATOR => {
                self._increment();

                if (next_char) |c| {
                    if (!ascii.isSymbol(c)) {
                        const t = token.Token{ .value = self.byte_buffer.slice, ._type = token.TokenType.BINARY_OPERATOR };
                        try self.tokens.append(t);
                        self.state = LexerState.COMPLETE_TOKEN;
                    }
                } else {
                    const t = token.Token{ .value = self.byte_buffer.slice, ._type = token.TokenType.BINARY_OPERATOR };
                    try self.tokens.append(t);
                    self.state = LexerState.COMPLETE_TOKEN;
                }
            },
            LexerState.OPEN_PAREN => {
                try self._single_char_token(token.TokenType.OPEN_PAREN);
            },
            LexerState.CLOSE_PAREN => {
                try self._single_char_token(token.TokenType.CLOSE_PAREN);
            },
            LexerState.OPEN_BRACKET => {
                try self._single_char_token(token.TokenType.OPEN_BRACKET);
            },
            LexerState.CLOSE_BRACKET => {
                try self._single_char_token(token.TokenType.CLOSE_BRACKET);
            },
            LexerState.OPEN_CURLY_BRACE => {
                try self._single_char_token(token.TokenType.OPEN_CURLY_BRACE);
            },
            LexerState.CLOSE_CURLY_BRACE => {
                try self._single_char_token(token.TokenType.CLOSE_CURLY_BRACE);
            },
            LexerState.WHITE_SPACE => {
                self._increment();

                if (next_char) |c| {
                    if (!ascii.isWhiteSpace(c)) {
                        const t = token.Token{ .value = self.byte_buffer.slice, ._type = token.TokenType.WHITE_SPACE };
                        try self.tokens.append(t);
                        self.state = LexerState.COMPLETE_TOKEN;
                    }
                } else {
                    const t = token.Token{ .value = self.byte_buffer.slice, ._type = token.TokenType.WHITE_SPACE };
                    try self.tokens.append(t);
                    self.state = LexerState.COMPLETE_TOKEN;
                }
            },
            LexerState.LINE_BREAK => {
                try self._single_char_token(token.TokenType.LINE_BREAK);
            },
        }
    }

    fn _increment(self: *Self) void {
        self.pos += 1;
        self.byte_buffer = StringSlice{ .slice = self.source[self.byte_buffer.start_idx..self.pos], .start_idx = self.byte_buffer.start_idx };
    }

    fn _single_char_token(self: *Self, token_type: token.TokenType) !void {
        self._increment();
        const t = token.Token{ .value = self.byte_buffer.slice, ._type = token_type };
        try self.tokens.append(t);
        self.state = LexerState.COMPLETE_TOKEN;
    }
};
