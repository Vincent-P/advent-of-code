const std = @import("std");
const expect = std.testing.expect;
const allocator = std.heap.page_allocator;

const Result = struct {
    score: i32 = 0,
};

const FLOOR_SIZE: usize = 1024;

pub fn process(input: []const u8) !Result {
    var floor: [FLOOR_SIZE][FLOOR_SIZE]i32 = undefined;
    for (floor) |row, i_row| {
        for (row) |_, i_col| {
            floor[i_row][i_col] = 0;
        }
    }

    var lines = std.mem.split(u8, input, "\n");
    const stdout = std.io.getStdOut().writer();

    while (true) {
        const line = lines.next() orelse break;
        var positions_iter = std.mem.tokenize(u8, line, " ->,");

        var x1 = try std.fmt.parseInt(i32, positions_iter.next().?, 10);
        var y1 = try std.fmt.parseInt(i32, positions_iter.next().?, 10);
        const x2 = try std.fmt.parseInt(i32, positions_iter.next().?, 10);
        const y2 = try std.fmt.parseInt(i32, positions_iter.next().?, 10);

        std.debug.assert(x1 < FLOOR_SIZE and y1 < FLOOR_SIZE and x2 < FLOOR_SIZE and y2 < FLOOR_SIZE);

        var x_step: i32 = if (x2 > x1) 1 else -1;
        var y_step: i32 = if (y2 > y1) 1 else -1;
        if (x1 == x2) x_step = 0;
        if (y1 == y2) y_step = 0;
        while (true) {
            floor[@intCast(u32, y1)][@intCast(u32, x1)] += 1;
            if (x1 == x2 and y1 == y2) break;
            x1 += x_step;
            y1 += y_step;
        }
    }


    var result = Result{};
    for (floor) |row| {
        for (row) |value| {
            result.score += @boolToInt(value >= 2);

        }

    }
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
    const result = try process(
        \\0,9 -> 5,9
        \\8,0 -> 0,8
        \\9,4 -> 3,4
        \\2,2 -> 2,1
        \\7,0 -> 7,4
        \\6,4 -> 2,0
        \\0,9 -> 2,9
        \\3,4 -> 1,4
        \\0,0 -> 8,8
        \\5,5 -> 8,2
    );

    try expect(result.score == 12);
}
