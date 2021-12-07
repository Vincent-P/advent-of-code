const std = @import("std");
const expect = std.testing.expect;

const Result = struct {
    gamma_rate: u16 = 0,
    epsilon_rate: u16 = 0,
    end_value: u64 = 0,
};

pub fn process(input: []const u8) !Result {
    const stdout = std.io.getStdOut().writer();
    var result = Result{};

    var bit_count = [_]i32{
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
    };

    const one: u16 = 1;
    var i: usize = 0;
    var number_count: u32 = 0;
    while (i < input.len) {
        var i_eol = i;
        while (i_eol < input.len and input[i_eol] != '\n') {
            i_eol += 1;
        }

        const n: u16 = try std.fmt.parseUnsigned(u16, input[i..i_eol], 2);

        var i_bit: u4 = 0;
        while (i_bit < bit_count.len) {
            defer i_bit += 1;
            bit_count[i_bit] += @boolToInt((n & (one << i_bit)) != 0);
        }

        i = i_eol + 1;
        number_count += 1;
    }

    var i_bit: u4 = 0;
    while (i_bit < bit_count.len) {
        defer i_bit += 1;

        if (bit_count[i_bit] > number_count / 2) {
            result.gamma_rate = result.gamma_rate | (one << i_bit);
        } else {
            result.epsilon_rate = result.epsilon_rate | (one << i_bit);
        }
    }

    result.end_value = @as(u64, result.gamma_rate) * @as(u64, result.epsilon_rate);

    try stdout.print("\n{any}\n", .{bit_count});
    try stdout.print("\n{}\n", .{result});
    try stdout.print("\n{b} {b}\n", .{ result.gamma_rate, result.epsilon_rate });

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

    try stdout.print("{}\n", .{result.end_value});
}

test "example" {
    const result = try process(
        \\00100
        \\11110
        \\10110
        \\10111
        \\10101
        \\01111
        \\00111
        \\11100
        \\10000
        \\11001
        \\00010
        \\01010
    );

    _ = result;
    try expect(result.gamma_rate == 22 and result.epsilon_rate == 9);
}
