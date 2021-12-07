const std = @import("std");

fn count_increases(numbers: std.ArrayList(i32)) !i32 {
    for (numbers.items) |number| {
        try std.io.getStdOut().writer().print("{}\n", .{number});
    }

    var increased: i32 = 0;
    var last_number = numbers.items[0];
    for (numbers.items) |number| {
        if (number > last_number) {
            increased += 1;
        }
        last_number = number;
    }
    return increased;
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

    var numbers = std.ArrayList(i32).init(allocator);
    defer numbers.deinit();

    while (true) {
        const line = (try input_reader.readUntilDelimiterOrEof(buffer, '\n')) orelse break;
        var n = try std.fmt.parseInt(i32, line, 10);
        try numbers.append(n);
    }

    var sliding_windows = std.ArrayList(i32).init(allocator);
    defer sliding_windows.deinit();

    var i: usize = 0;
    while (i < numbers.items.len - 2) {
        var sliding_window = numbers.items[i] + numbers.items[i + 1] + numbers.items[i + 2];
        try sliding_windows.append(sliding_window);
        i += 1;
    }

    const count = try count_increases(sliding_windows);
    try stdout.print("increased {} times\n", .{count});
}
