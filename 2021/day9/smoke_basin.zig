const std = @import("std");
const expect = std.testing.expect;
const allocator = std.heap.page_allocator;

fn get_basin_size(heightmap: std.ArrayList(i8), width: usize, height: usize, i_row: usize, i_col: usize) usize {
    if (i_row >= height or i_col >= width) return 0;

    const cur = heightmap.items[i_row * width + i_col];
    if (cur == 9) return 0;

    heightmap.items[i_row * width + i_col] = 9;

    return get_basin_size(heightmap, width, height, i_row + 1, i_col)
        + get_basin_size(heightmap, width, height, i_row, i_col + 1)
        + get_basin_size(heightmap, width, height, i_row -% 1, i_col)
        + get_basin_size(heightmap, width, height, i_row, i_col -% 1)
        + 1;
}

pub fn process(input: []const u8) !usize {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("\n", .{});

    var line_iter = std.mem.split(u8, input, "\n");
    var line = line_iter.next().?;

    const width = line.len;
    var height: usize = 0;

    var heightmap = try std.ArrayList(i8).initCapacity(allocator, width * width);
    defer heightmap.deinit();

    // Read the heightmap
    while (true) {
        for (line) |char| {
            const n: i8 = @intCast(i8, char - '0');
            try heightmap.append(n);
        }
        height += 1;
        line = line_iter.next() orelse break;
    }

    // Count low points
    var score: usize = 0;

    var lower_points = std.ArrayList([2]usize).init(allocator);
    defer lower_points.deinit();

    var i_row: usize = 0;
    while (i_row < height) : (i_row += 1) {
        var i_col: usize = 0;
        while (i_col < width) : (i_col += 1) {
            const current = heightmap.items[i_row * width + i_col];
            const lt_top = (i_row == 0) or (current < heightmap.items[(i_row - 1) * width + i_col]);
            const lt_right = (i_col == width - 1) or (current < heightmap.items[i_row * width + (i_col + 1)]);
            const lt_bottom = (i_row == height - 1) or (current < heightmap.items[(i_row + 1) * width + i_col]);
            const lt_left = (i_col == 0) or (current < heightmap.items[i_row * width + (i_col - 1)]);
            const lower = lt_top and lt_right and lt_bottom and lt_left;

            if (lower) {
                try lower_points.append([2]usize{i_row, i_col});
            }
        }
    }

    var basin_sizes = std.ArrayList(usize).init(allocator);
    defer basin_sizes.deinit();
    for (lower_points.items) |lower_point| {
        i_row = lower_point[0];
        const i_col = lower_point[1];
        const current = heightmap.items[i_row * width + i_col];
        try stdout.print("lower point: {} ({}, {})\n", .{current, i_col, i_row});
        const basin_size = get_basin_size(heightmap, width, height, i_row, i_col);
        try stdout.print("basin size: {}\n\n", .{basin_size});
        try basin_sizes.append(basin_size);
    }


    std.sort.sort(usize, basin_sizes.items, {}, comptime std.sort.desc(usize));
    score = 1;
    if (basin_sizes.items.len > 1) { score *= basin_sizes.items[0]; try stdout.print("{}\n", .{basin_sizes.items[0]}); }
    if (basin_sizes.items.len > 2) { score *= basin_sizes.items[1]; try stdout.print("{}\n", .{basin_sizes.items[1]}); }
    if (basin_sizes.items.len > 3) { score *= basin_sizes.items[2]; try stdout.print("{}\n", .{basin_sizes.items[2]}); }

    // Debug print
    i_row = 0;
    while (i_row < height) : (i_row += 1) {
        var i_col: usize = 0;
        while (i_col < width) : (i_col += 1) {
            try stdout.print("{} ", .{heightmap.items[i_row * width + i_col]});
        }
        try stdout.print("\n", .{});
    }

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
        \\2199943210
        \\3987894921
        \\9856789892
        \\8767896789
        \\9899965678
    );
    try expect(score == 1134);
}
