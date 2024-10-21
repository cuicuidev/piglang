const std = @import("std");
const lexer = @import("lexer.zig");

pub fn main() !void {
    const source_code =
        \\pub fn main() -> !void:
        \\    const x: u8 = 100
        \\    y: f32 = 69.0
        \\    
        \\    y += 420.0
        \\    y = y + @asFloat(f32, x)
        \\    
        \\    z: u8 = 0b00011001
        \\    i: f64 = 6.02214076e+23
        \\    j: u16 = 0x18A8
        \\    k: f32 = 3.14e+10-9
        \\    
        \\    @println("Result: {d}", .{y})
    ;

    const stdout = std.io.getStdOut().writer();
    try stdout.writeAll(source_code);
    try stdout.writeAll("\n\n");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var allocator = gpa.allocator();

    var l = lexer.Lexer.init(&allocator, source_code);
    defer l.deinit();

    try l.tokenize();
    try l.printTokens(stdout);
}
