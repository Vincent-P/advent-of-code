const std = @import("std");
const expect = std.testing.expect;
const allocator = std.heap.page_allocator;

pub fn process(input: []const u8) !i64 {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("\n", .{});

    var line_iter = std.mem.split(u8, input, "\n");

    var grid: [10][10]i8 = undefined;
    var has_flashed: [10][10]bool = undefined;

    // read the grid
    var i_line: usize = 0;
    while (true) {
        const line = line_iter.next() orelse break;
        var i_col: usize = 0;
        for (line) |char| {
            grid[i_line][i_col] = @intCast(i8, char - '0');
            i_col += 1;
        }
        i_line += 1;
    }

    var i_step: usize = 0;
    while (i_step < 1000) : (i_step += 1) {
        var flash_count: i64 = 0;

        // reset flash
        for (has_flashed) |row, i_row| {
            for (row) |_, i_col| {
                has_flashed[i_row][i_col] = false;
            }
        }

        // increase all energy by 1
        for (grid) |row, i_row| {
            for (row) |_, i_col| {
                grid[i_row][i_col] += 1;
            }
        }

        // flash all >= 9
        var atleast_one_flash = true;
        while (atleast_one_flash) {
            atleast_one_flash = false;
            for (grid) |row, i_row| {
                for (row) |value, i_col| {
                    if (value > 9 and !has_flashed[i_row][i_col]) {
                        has_flashed[i_row][i_col] = true;
                        atleast_one_flash = true;
                        flash_count += 1;

                        // increase neighbors' energy
                        if (i_row > 0 and i_col > 0) {
                            grid[i_row-1][i_col-1] += 1;
                        }
                        if (i_row > 0) {
                            grid[i_row-1][i_col] += 1;
                        }
                        if (i_row > 0 and i_col + 1 < 10) {
                            grid[i_row-1][i_col+1] += 1;
                        }
                        if (i_col + 1 < 10) {
                            grid[i_row][i_col+1] += 1;
                        }
                        if (i_row + 1 < 10 and i_col + 1 < 10) {
                            grid[i_row+1][i_col+1] += 1;
                        }
                        if (i_row + 1 < 10) {
                            grid[i_row+1][i_col] += 1;
                        }
                        if (i_row + 1 < 10 and i_col > 0) {
                            grid[i_row+1][i_col-1] += 1;
                        }
                        if (i_col > 0) {
                            grid[i_row][i_col-1] += 1;
                        }
                    }
                }
            }
        }

        // reset energy count for octopuses that flashed
        for (has_flashed) |row, i_row| {
            for (row) |flashed, i_col| {
                if (flashed) {
                    grid[i_row][i_col] = 0;
                }
            }
        }

        if (flash_count == 100) {
            break;
        }
    }

    var score: i64 = @intCast(i64, i_step + 1);

    try stdout.print("\nscore: {}\n", .{score});
    return score;
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

test "short example" {
    const score = try process(
        \\5483143223
        \\2745854711
        \\5264556173
        \\6141336146
        \\6357385478
        \\4167524645
        \\2176841721
        \\6882881134
        \\4846848554
        \\5283751526
    );
    try expect(score == 195);
}
