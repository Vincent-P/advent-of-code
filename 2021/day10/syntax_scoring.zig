const std = @import("std");
const expect = std.testing.expect;
const allocator = std.heap.page_allocator;

const VisitResult = struct { incomplete: bool, valid: bool, index: usize };

fn parse_block(line: []const u8, i: usize, missing_chars: *std.ArrayList(u8)) VisitResult {
    if (i >= line.len) {
        return VisitResult{ .incomplete = true, .valid = true, .index = line.len - 1 };
    }

    switch (line[i]) {
        '(', '{', '[', '<' => {
            const expected: u8 = switch (line[i]) {
                '(' => ')',
                '{' => '}',
                '[' => ']',
                '<' => '>',
                else => unreachable,
            };

            var index = i + 1; // consume current char

            while (index < line.len and line[index] != expected) {
                const inner_res = parse_block(line, index, missing_chars);
                if (!inner_res.valid) {
                    return inner_res;
                }
                index = inner_res.index;
            }

            if (index >= line.len) {
                missing_chars.*.append(expected) catch unreachable;
            }

            return VisitResult{
                .incomplete = index >= line.len,
                .valid = index >= line.len or line[index] == expected,
                .index = index + 1,
            };
        },
        ')', '}', ']', '>' => {
            return VisitResult{
                .incomplete = false,
                .valid = false,
                .index = i,
            };
        },
        else => {
            unreachable;
        },
    }
}

pub fn process(input: []const u8) !i64 {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("\n", .{});

    var line_iter = std.mem.split(u8, input, "\n");

    var completion_scores = std.ArrayList(i64).init(allocator);
    defer completion_scores.deinit();

    while (true) {
        const line = line_iter.next() orelse break;

        var missing_chars = std.ArrayList(u8).init(allocator);
        defer missing_chars.deinit();

        var res = VisitResult{ .incomplete = true, .valid = true, .index = 0 };
        while (res.valid and res.index < line.len) {
            res = parse_block(line, res.index, &missing_chars);
        }

        if (res.incomplete == true) {
            try stdout.print("{s} -- {s}\n", .{ line, missing_chars.items });
            var completion_score: i64 = 0;
            for (missing_chars.items) |char| {
                const char_score: i64 = switch (char) {
                    ')' => 1,
                    ']' => 2,
                    '}' => 3,
                    '>' => 4,
                    else => unreachable,
                };
                completion_score = completion_score * 5 + char_score;

            }
            try completion_scores.append(completion_score);
        }
    }

    std.sort.sort(i64, completion_scores.items, {}, comptime std.sort.asc(i64));

    var score: i64 = completion_scores.items[completion_scores.items.len / 2];

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
        \\[({(<(())[]>[[{[]{<()<>>
        \\[(()[<>])]({[<{<<[]>>(
        \\{([(<{}[<>[]}>{[]{[(<()>
        \\(((({<>}<{<{<>}{[]{[]{}
        \\[[<[([]))<([[{}[[()]]]
        \\[{[{({}]{}}([{[{{{}}([]
        \\{<[[]]>}<{[{[{[]{()[[[]
        \\[<(<(<(<{}))><([]([]()
        \\<{([([[(<>()){}]>(<<{{
        \\<{([{{}}[<[[[<>{}]]]>[]]
    );
    try expect(score == 288957);
}
