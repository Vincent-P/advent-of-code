const std = @import("std");
const expect = std.testing.expect;
const allocator = std.heap.page_allocator;

const Result = struct {
    score: u64 = 0,
};

pub fn process(input: []const u8) !Result {
    var fish_count_per_age = [_]u64{0} ** 9;

    const stdout = std.io.getStdOut().writer();
    var fish_iter = std.mem.tokenize(u8, input, ",\n ");

    while (true) {
        const fish_str = fish_iter.next() orelse break;
        const fish_age = try std.fmt.parseInt(u8, fish_str, 10);
        fish_count_per_age[fish_age] += 1;
    }

    var i_day: u32 = 0;
    while (i_day < 256) : (i_day += 1) {
        if (false) {
        try stdout.print("day {} - 0:{} 1:{} 2:{} 3:{} 4:{} 5:{} 6:{} 7:{} 8:{}\n", .{
            i_day,
            fish_count_per_age[0], fish_count_per_age[1], fish_count_per_age[2], fish_count_per_age[3],
            fish_count_per_age[4], fish_count_per_age[5], fish_count_per_age[6], fish_count_per_age[7],
            fish_count_per_age[8],
        });
        }

        const new_fishes = fish_count_per_age[0];
        fish_count_per_age[0] = fish_count_per_age[1];
        fish_count_per_age[1] = fish_count_per_age[2];
        fish_count_per_age[2] = fish_count_per_age[3];
        fish_count_per_age[3] = fish_count_per_age[4];
        fish_count_per_age[4] = fish_count_per_age[5];
        fish_count_per_age[5] = fish_count_per_age[6];
        fish_count_per_age[6] = fish_count_per_age[7] + new_fishes;
        fish_count_per_age[7] = fish_count_per_age[8];
        fish_count_per_age[8] = new_fishes;
    }

    var result = Result{};
    var i_count: usize = 0;
    while (i_count < 9) : (i_count += 1) {
        result.score += fish_count_per_age[i_count];
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
    const result = try process("3,4,3,1,2");

    try expect(result.score == 26984457539);
}
