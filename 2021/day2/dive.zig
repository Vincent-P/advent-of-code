const std = @import("std");

const Result = struct {
    horizontal: i32 = 0,
    depth: i32 = 0,
    aim: i32 = 0,
};

const CommandType = enum {
    down,
    forward,
    up,
};

const Command = struct {
    type: CommandType,
    value: i32,
};

pub fn process(input: []const u8) !Result {
    const stdout = std.io.getStdOut().writer();
    const allocator = std.heap.page_allocator;

    var result = Result{};
    var commands = std.ArrayList(Command).init(allocator);
    defer commands.deinit();

    var tokens = std.mem.tokenize(u8, input, " \n");
    while (true) {
        const command_str = tokens.next() orelse break;
        const value_str = tokens.next() orelse break;

        var command = CommandType.down;
        if (std.mem.eql(u8, command_str, "down")) {
            command = CommandType.down;
        } else if (std.mem.eql(u8, command_str, "forward")) {
            command = CommandType.forward;
        } else if (std.mem.eql(u8, command_str, "up")) {
            command = CommandType.up;
        } else {
            unreachable;
        }

        const value = try std.fmt.parseInt(i32, value_str, 10);

        try commands.append(Command{ .type = command, .value = value });
    }

    for (commands.items) |command| {
        try stdout.print("{}\n", .{command});

        switch (command.type) {
            .forward => {
                result.horizontal += command.value;
                result.depth += result.aim * command.value;
            },
            .down => result.aim += command.value,
            .up => result.aim -= command.value,
        }
    }
    try stdout.print("{}\n", .{result});

    return result;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const allocator = std.heap.page_allocator;

    const current_dir = std.fs.cwd();
    const input_file = try current_dir.openFile("input", std.fs.File.OpenFlags{});
    const input_stat = try input_file.stat();
    const input_reader = input_file.reader();

    const buffer = try allocator.alloc(u8, input_stat.size);
    defer allocator.free(buffer);

    _ = try input_reader.readAll(buffer);

    const result = try process(buffer);

    try stdout.print("{}\n", .{result.depth * result.horizontal});
}

test "example" {
    const expect = std.testing.expect;
    const result = try process(
        \\forward 5
        \\down 5
        \\forward 8
        \\up 3
        \\down 8
        \\forward 2
    );

    try expect(result.horizontal == 15);
    try expect(result.depth == 60);
}
