const std = @import("std");
const expect = std.testing.expect;

pub fn process(allocator: std.mem.Allocator, input: []const u8) i64 {
    const stdout = std.io.getStdOut().writer();
    stdout.print("\n", .{}) catch unreachable;

    const Polymer = std.TailQueue(u8);
    var polymer = Polymer{};

    var insertions = std.StringArrayHashMap(u8).init(allocator);
    defer insertions.deinit();

    var line_iter = std.mem.split(u8, input, "\n");
    const first_line = line_iter.next().?;

    for (first_line) |char| {
        var node_ptr = allocator.create(Polymer.Node) catch unreachable;
        node_ptr.* = Polymer.Node{ .data = char };
        polymer.append(node_ptr);
    }

    //stdout.print("polymer: {s}\n", .{polymer.items}) catch unreachable;

    var insertions_iter = std.mem.tokenize(u8, line_iter.rest(), "\n ->");
    while (true) {
        const start = insertions_iter.next() orelse break;
        const end = insertions_iter.next() orelse break;

        const insertion = insertions.getOrPut(start) catch unreachable;
        insertion.value_ptr.* = end[0];
    }

    var i_step: usize = 0;
    while (i_step < 40) : (i_step += 1) {
        var it = polymer.first;
        while (it != null and it.?.next != null) {
            var pair = [2]u8 {0, 0};
            pair[0] = it.?.data;
            pair[1] = it.?.next.?.data;

            // stdout.print("{s}\n", .{pair}) catch unreachable;
            if (insertions.get(pair[0..2])) |new_char| {
                // stdout.print("insertion: {s} -> {c}\n", .{pair, new_char}) catch unreachable;
                var node_ptr = allocator.create(Polymer.Node) catch unreachable;
                node_ptr.* = Polymer.Node{ .data = new_char };
                it = it.?.next.?;
                polymer.insertAfter(it.?, node_ptr);
            }

            it = it.?.next.?;
        }

        stdout.print("after step {}: \n", .{i_step+1}) catch unreachable;
    }

    var i_max: usize = 0;
    var i_min: usize = 0;
    var count_per_char = [_]i64 {0} ** 26;
    var it = polymer.first;
    while (it) |node| {
        const i: usize = node.data - 'A';
        count_per_char[i] += 1;
        if (count_per_char[i_max] == 0
                or (count_per_char[i] > 0 and count_per_char[i] > count_per_char[i_max])) {
            i_max = i;
        }
        if (count_per_char[i_min] == 0 or
                (count_per_char[i] > 0 and count_per_char[i] < count_per_char[i_min])) {
            i_min = i;
        }
    }

    for (count_per_char) |count, i_char| {
        stdout.print("count of {c}: {}\n", .{@intCast(u8, 'A' + i_char), count}) catch unreachable;
    }

    var score: i64 = count_per_char[i_max] - count_per_char[i_min];

    stdout.print("\nscore: {}\n", .{score}) catch unreachable;
    return score;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const current_dir = std.fs.cwd();
    const input_file = try current_dir.openFile("input", std.fs.File.OpenFlags{});
    const input_stat = try input_file.stat();
    const input_reader = input_file.reader();

    const buffer = try allocator.alloc(u8, input_stat.size);
    _ = try input_reader.readAll(buffer);

    _ = process(allocator, buffer);
}

test "short example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const score = process(allocator,
        \\NNCB
        \\
        \\CH -> B
        \\HH -> N
        \\CB -> H
        \\NH -> C
        \\HB -> C
        \\HC -> B
        \\HN -> C
        \\NN -> C
        \\BH -> H
        \\NC -> B
        \\NB -> B
        \\BN -> B
        \\BB -> N
        \\BC -> B
        \\CC -> N
        \\CN -> C
    );
    try expect(score == 2188189693529);
}
