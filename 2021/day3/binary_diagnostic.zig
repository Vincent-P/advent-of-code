const std = @import("std");
const expect = std.testing.expect;
const allocator = std.heap.page_allocator;

const Result = struct {
    gamma: u16 = 0,
    epsilon: u16 = 0,
    end: u64 = 0,
};

pub fn process(input: []const u8) !Result {
    var result = Result{};

    var bit_count = [_]i32{0} ** 16;
    const one: u16 = 1;

    var tokens = std.mem.tokenize(u8, input, "\n");

    var numbers = std.ArrayList(u16).init(allocator);
    defer numbers.deinit();

    var bit_max_count: usize = 0;

    while (true) {
        const line = tokens.next() orelse break;
        const number: u16 = try std.fmt.parseUnsigned(u16, line, 2);

        try numbers.append(number);
        bit_max_count = std.math.max(bit_max_count, line.len);
    }

    std.debug.assert(bit_max_count <= bit_count.len);

    for (numbers.items) |number| {
        var i_bit: u4 = 0;
        while (i_bit < bit_max_count) {
            bit_count[i_bit] += @boolToInt((number & (one << i_bit)) != 0);
            i_bit += 1;
        }
    }

    var i_bit: u4 = 0;
    while (i_bit < bit_max_count) {
        if (bit_count[i_bit] > numbers.items.len / 2) {
            result.gamma = result.gamma | (one << i_bit);
        } else {
            result.epsilon = result.epsilon | (one << i_bit);
        }

        i_bit += 1;
    }

    result.end = @as(u64, result.gamma) * @as(u64, result.epsilon);

    return result;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const current_dir = std.fs.cwd();
    const input_file = try current_dir.openFile("input", std.fs.File.OpenFlags{});
    const input_stat = try input_file.stat();
    const input_reader = input_file.reader();

    const buffer = try allocator.alloc(u8, input_stat.size);

    _ = try input_reader.readAll(buffer);

    const result = try process(buffer);

    try stdout.print("{}\n", .{result.end});
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
    try expect(result.gamma == 22 and result.epsilon == 9);
}
