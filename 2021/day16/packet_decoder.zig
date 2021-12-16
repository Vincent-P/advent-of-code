const std = @import("std");
const expect = std.testing.expect;

fn parse_packet(reader: anytype, bread: *usize) i64 {
    const stdout = std.io.getStdOut().writer();

    var result: i64 = 0;
    const version = reader.readBitsNoEof(u3, 3) catch unreachable; bread.* += 3;
    const type_id = reader.readBitsNoEof(u3, 3) catch unreachable; bread.* += 3;
    _ = version;

    if (type_id == 4) {
        var literal_value: u64 = 0;
        while (true) {
            const is_last = reader.readBitsNoEof(u1, 1) catch unreachable; bread.* += 1;
            const group_value = reader.readBitsNoEof(u32, 4) catch unreachable; bread.* += 4;
            literal_value = (literal_value << 4) | group_value;
            if (is_last == 0) {
                break;
            }
        }
        result = @intCast(i64, literal_value);
        stdout.print("{}", .{literal_value}) catch unreachable;
    } else {
        const length_type_id = reader.readBitsNoEof(u1, 1) catch unreachable; bread.* += 1;

        var bit_length: ?usize = null;
        var packet_length: ?usize = null;

        if (length_type_id == 0) {
            bit_length = reader.readBitsNoEof(u32, 15) catch unreachable;
            bread.* += 15;
        } else {
            packet_length = reader.readBitsNoEof(u11, 11) catch unreachable;
            bread.* += 11;
        }

        var inner_bread: usize = 0;
        var i_packet: usize = 1;

        stdout.print("(", .{}) catch unreachable;
        if (type_id == 0) {stdout.print("+", .{}) catch unreachable;}
        if (type_id == 1) {stdout.print("*", .{}) catch unreachable;}
        if (type_id == 2) {stdout.print("min", .{}) catch unreachable;}
        if (type_id == 3) {stdout.print("max", .{}) catch unreachable;}
        if (type_id == 5) {stdout.print(">", .{}) catch unreachable;}
        if (type_id == 6) {stdout.print("<", .{}) catch unreachable;}
        if (type_id == 7) {stdout.print("==", .{}) catch unreachable;}
        stdout.print(" ", .{}) catch unreachable;

        var lhs = parse_packet(reader, &inner_bread);

        while ((bit_length != null and inner_bread < bit_length.?)
            or (packet_length != null and i_packet < packet_length.?)) {

            stdout.print(" ", .{}) catch unreachable;
            const rhs = parse_packet(reader, &inner_bread);

            switch (type_id) {
                0 => lhs += rhs,
                1 => lhs *= rhs,
                2 => lhs = if (lhs < rhs) lhs else rhs,
                3 => lhs = if (lhs > rhs) lhs else rhs,
                5 => {lhs = @boolToInt(lhs > rhs); break;},
                6 => {lhs = @boolToInt(lhs < rhs); break;},
                7 => {lhs = @boolToInt(lhs == rhs); break;},
                else => unreachable,
            }

            i_packet += 1;
        }
        stdout.print(")", .{}) catch unreachable;
        bread.* += inner_bread;

        result = lhs;
    }

    return result;
}

fn char_to_hex(c: u8) u8 {
    if ('0' <= c and c <= '9') {
        return c - '0';
    } else if ('A' <= c and c <= 'F') {
        return 10 + c - 'A';
    } else {
        unreachable;
    }
}

pub fn process(allocator: std.mem.Allocator, input: []const u8) i64 {
    const stdout = std.io.getStdOut().writer();
    stdout.print("\n", .{}) catch unreachable;

    const buffer = allocator.alloc(u8, input.len >> 1) catch unreachable;
    var i_buf: usize = 0;
    while (i_buf < input.len >> 1) : (i_buf += 1) {
        buffer[i_buf] = (char_to_hex(input[2 * i_buf]) << 4) | char_to_hex(input[2 * i_buf + 1]);
    }

    var stream = std.io.fixedBufferStream(@as([]u8, buffer));
    var reader = std.io.bitReader(.Big, stream.reader());

    var bread: usize = 0;
    var score: i64 = parse_packet(&reader, &bread);

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

test "example 1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const score = process(allocator, "C200B40A82");
    try expect(score == 3);
}

test "example 2" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const score = process(allocator, "04005AC33890");
    try expect(score == 54);
}

test "example 3" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const score = process(allocator, "880086C3E88112");
    try expect(score == 7);
}

test "example 4" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const score = process(allocator, "CE00C43D881120");
    try expect(score == 9);
}

test "example 5" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const score = process(allocator, "D8005AC2A8F0");
    try expect(score == 1);
}

test "example 6" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const score = process(allocator, "F600BC2D8F");
    try expect(score == 0);
}

test "example 7" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const score = process(allocator, "9C005AC2F8F0");
    try expect(score == 0);
}

test "example 8" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const score = process(allocator, "9C0141080250320F1802104A08");
    try expect(score == 1);
}

// 18247660798
