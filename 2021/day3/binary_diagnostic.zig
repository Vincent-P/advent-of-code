const std = @import("std");
const expect = std.testing.expect;
const allocator = std.heap.page_allocator;

const Result = struct {
    oxygen: u16 = 0,
    co2: u16 = 0,
    end: u64 = 0,
};

pub fn process(input: []const u8) !Result {
    var numbers = std.ArrayList(u16).init(allocator);
    defer numbers.deinit();

    var bit_max_count: u4 = 0;

    // read numbers and count the maximum number of bits in the input
    var tokens = std.mem.tokenize(u8, input, "\n");
    while (true) {
        const line = tokens.next() orelse break;
        const number: u16 = try std.fmt.parseUnsigned(u16, line, 2);

        try numbers.append(number);
        std.debug.assert(line.len < 16);
        bit_max_count = std.math.max(bit_max_count, @intCast(u4, line.len));
    }

    var oxygen_candidates = numbers;

    var co2_candidates = try std.ArrayList(u16).initCapacity(allocator, numbers.items.len);
    for (numbers.items) |number| {
        try co2_candidates.append(number);
    }

    var i_bit: u4 = 0;
    while (i_bit < bit_max_count) : (i_bit += 1) {
        const bitmask = @as(u16, 1) << (bit_max_count - i_bit - 1);

        var oxygen_bit_count: i32 = 0;
        for (oxygen_candidates.items) |candidate| {
            oxygen_bit_count += @boolToInt((candidate & bitmask) != 0);
        }
        const is_oxygen_majority_one = 2 * oxygen_bit_count >= oxygen_candidates.items.len;
        var i: usize = 0;
        while (i < oxygen_candidates.items.len and oxygen_candidates.items.len > 1) {
            const has_one = (oxygen_candidates.items[i] & bitmask) != 0;
            if (is_oxygen_majority_one == has_one) {
                i += 1;
            } else {
                _ = oxygen_candidates.swapRemove(i);
            }
        }

        var co2_bit_count: i32 = 0;
        for (co2_candidates.items) |candidate| {
            co2_bit_count += @boolToInt((candidate & bitmask) != 0);
        }
        const is_co2_majority_one = 2 * co2_bit_count >= co2_candidates.items.len;
        i = 0;
        while (i < co2_candidates.items.len and co2_candidates.items.len > 1) {
            const has_one = (co2_candidates.items[i] & bitmask) != 0;
            if (is_co2_majority_one != has_one) {
                i += 1;
            } else {
                _ = co2_candidates.swapRemove(i);
            }
        }
    }

    var result = Result{};
    result.oxygen = oxygen_candidates.items[0];
    result.co2 = co2_candidates.items[0];
    result.end = @as(u64, result.co2) * @as(u64, result.oxygen);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("\noxygen: {b}\n", .{result.oxygen});
    try stdout.print("co2: {b}\n", .{result.co2});
    try stdout.print("{}\n", .{result.end});
    return result;
}

pub fn main() !void {
    const current_dir = std.fs.cwd();
    const input_file = try current_dir.openFile("input", std.fs.File.OpenFlags{});
    const input_stat = try input_file.stat();
    const input_reader = input_file.reader();

    const buffer = try allocator.alloc(u8, input_stat.size);
    _ = try input_reader.readAll(buffer);

    _ = try process(buffer);
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

    try expect(result.oxygen == 23);
    try expect(result.co2 == 10);
    try expect(result.end == 230);
}
