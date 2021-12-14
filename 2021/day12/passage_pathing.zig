const std = @import("std");
const expect = std.testing.expect;

pub fn process(allocator: std.mem.Allocator, input: []const u8) i64 {
    const stdout = std.io.getStdOut().writer();
    stdout.print("\n", .{}) catch unreachable;

    var caves = std.ArrayList([]const u8).init(allocator);
    defer caves.deinit();

    var start: usize = 0;
    var end: usize = 0;

    var cave_iter = std.mem.tokenize(u8, input, "-\n");
    while (true) {
        const a = cave_iter.next() orelse break;
        const b = cave_iter.next().?;

        const a_index = for (caves.items) |cave, i| {
            if (std.mem.eql(u8, cave, a)) break i;
        } else eb: {
            const old_len = caves.items.len;
            caves.append(a) catch unreachable;
            break :eb old_len;
        };

        const b_index = for (caves.items) |cave, i| {
            if (std.mem.eql(u8, cave, b)) break i;
        } else eb: {
            const old_len = caves.items.len;
            caves.append(b) catch unreachable;
            break :eb old_len;
        };

        if (std.mem.eql(u8, a, "start")) {
            start = a_index;
        }
        else if (std.mem.eql(u8, a, "end")) {
            end = a_index;
        }

        if (std.mem.eql(u8, b, "start")) {
            start = b_index;
        }
        else if (std.mem.eql(u8, b, "end")) {
            end = b_index;
        }
    }

    const NodeQueue = std.TailQueue(usize);
    var node_queue = NodeQueue{};

    var node_ptr = allocator.create(NodeQueue.Node) catch unreachable;
    node_ptr.* = NodeQueue.Node{ .data = start };
    node_queue.append(node_ptr);

    while (true) {
        var node = node_queue.pop() orelse break;


    }

    var score: i64 = 0;

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
        \\start-A
        \\start-b
        \\A-c
        \\A-b
        \\b-d
        \\A-end
        \\b-end
    );
    try expect(score == 10);
}

test "long example" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const score = process(allocator,
        \\dc-end
        \\HN-start
        \\start-kj
        \\dc-start
        \\dc-HN
        \\LN-dc
        \\HN-end
        \\kj-sa
        \\kj-HN
        \\kj-dc
    );
    try expect(score == 226);
}
