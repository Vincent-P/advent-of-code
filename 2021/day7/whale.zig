const std = @import("std");
const expect = std.testing.expect;
const allocator = std.heap.page_allocator;

const Result = struct {
    score: i32 = 0,
};

pub fn process(input: []const u8) !Result {
    var numbers = try std.ArrayList(i32).initCapacity(allocator, 2 << 20);
    defer numbers.deinit();

    var numbers_iter = std.mem.tokenize(u8, input, ",\n ");

    while (true) {
        const number_str = numbers_iter.next() orelse break;
        const number = try std.fmt.parseInt(i32, number_str, 10);
        try numbers.append(number);
    }

    std.sort.sort(i32, numbers.items, {}, comptime std.sort.asc(i32));

    // const median = numbers.items[numbers.items.len / 2];
    var mean: i32 = 0;
    for (numbers.items) |number| {
        mean += number;
    }
    mean = @floatToInt(i32, std.math.round(@intToFloat(f32, mean) / @intToFloat(f32, numbers.items.len)));


    var distance_to_median: i32 = 0;
    for (numbers.items) |number| {
        const distance = try std.math.absInt(number - mean);
        distance_to_median += @divExact(distance * (distance + 1), 2);
    }

    const stdout = std.io.getStdOut().writer();
    var result = Result{};
    result.score = distance_to_median;

    try stdout.print("\nscore: {}\n", .{result.score});
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
    const result = try process("16,1,2,0,4,2,7,1,2,14");

    try expect(result.score == 168);
}
