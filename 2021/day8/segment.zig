const std = @import("std");
const expect = std.testing.expect;
const allocator = std.heap.page_allocator;

fn str_contains(string: []const u8, needle: u8) bool {
    for (string) |char| {
        if (char == needle) {
            return true;
        }
    }
    return false;
}

fn str_value(string: []const u8, a: u8, b: u8, c:u8, d:u8, e: u8, f: u8, g:u8) i32 {
    var has_a = false;
    var has_b = false;
    var has_c = false;
    var has_d = false;
    var has_e = false;
    var has_f = false;
    var has_g = false;

    for (string) |char| {
        has_a = has_a or char == a;
        has_b = has_b or char == b;
        has_c = has_c or char == c;
        has_d = has_d or char == d;
        has_e = has_e or char == e;
        has_f = has_f or char == f;
        has_g = has_g or char == g;
    }

    if (has_a and has_b and has_c and !has_d and has_e and has_f and has_g) {
        return 0;
    }
    else if (!has_a and !has_b and has_c and !has_d and !has_e and has_f and !has_g) {
        return 1;
    }
    else if (has_a and !has_b and has_c and has_d and has_e and !has_f and has_g) {
        return 2;
    }
    else if (has_a and !has_b and has_c and has_d and !has_e and has_f and has_g) {
        return 3;
    }
    else if (!has_a and has_b and has_c and has_d and !has_e and has_f and !has_g) {
        return 4;
    }
    else if (has_a and has_b and !has_c and has_d and !has_e and has_f and has_g) {
        return 5;
    }
    else if (has_a and has_b and !has_c and has_d and has_e and has_f and has_g) {
        return 6;
    }
    else if (has_a and !has_b and has_c and !has_d and !has_e and has_f and !has_g) {
        return 7;
    }
    else if (has_a and has_b and has_c and has_d and has_e and has_f and has_g) {
        return 8;
    }
    else if (has_a and has_b and has_c and has_d and !has_e and has_f and has_g) {
        return 9;
    }
    else {
        unreachable;
    }
}

pub fn process(input: []const u8) !i32 {
    var numbers = try std.ArrayList(i32).initCapacity(allocator, 2 << 20);
    defer numbers.deinit();

    var line_iter = std.mem.split(u8, input, "\n");

    const stdout = std.io.getStdOut().writer();
    try stdout.print("\n", .{});

    var score: i32 = 0;

    while (true) {
        const line_str = line_iter.next() orelse break;

        var signals: [10][]const u8 = undefined;
        var outputs: [4][]const u8 = undefined;

        // Read all signal and outputs
        var token_iter = std.mem.tokenize(u8, line_str, " |");
        for (signals) |*signal| {
            const token_str = token_iter.next().?;
            signal.* = token_str;
        }
        for (outputs) |*output| {
            const token_str = token_iter.next().?;
            output.* = token_str;
        }

        // Process
        var c: u8 = 0;
        var f: u8 = 0;

        var a: u8 = 0;

        var b: u8 = 0;
        var d: u8 = 0;

        var e: u8 = 0;
        var g: u8 = 0;

        // find c and f in 1
        for (signals) |signal| {
            if (signal.len == 2) {
                c = signal[0];
                f = signal[1];
                break;
            }
        }
        std.debug.assert(c != 0);
        std.debug.assert(f != 0);

        // find a in 7
        for (signals) |signal| {
            if (signal.len == 3) {
                for (signal) |signal_char| {
                    if (signal_char != c and signal_char != f) {
                        a = signal_char;
                        break;
                    }
                }
            }
        }
        std.debug.assert(a != 0);

        // find b and d in 4
        for (signals) |signal| {
            if (signal.len == 4) {
                for (signal) |signal_char| {
                    const is_new = signal_char != c and signal_char != f;
                    if (is_new and b == 0) {
                        b = signal_char;
                    }
                    else if (is_new and b != 0) {
                        d = signal_char;
                    }
                }
                break;
            }
        }
        std.debug.assert(b != 0);
        std.debug.assert(d != 0);

        // find e and g in 8
        for (signals) |signal| {
            if (signal.len == 7) {
                for (signal) |signal_char| {
                    const is_new = signal_char != c and signal_char != f and signal_char != a and signal_char != b and signal_char != d;
                    if (is_new and e == 0) {
                        e = signal_char;
                    }
                    else if (is_new and e != 0) {
                        g = signal_char;
                    }
                }
                break;
            }
        }
        std.debug.assert(e != 0);
        std.debug.assert(g != 0);

        // check if c and f need to be swapped
        var candidate_count: i32 = 0;
        for (signals) |signal| {
            candidate_count += @boolToInt(str_contains(signal, c));
        }
        std.debug.assert(candidate_count == 8 or candidate_count == 9);
        if (candidate_count != 8) {
            std.mem.swap(u8, &c, &f);
        }

        // check if b and d need to be swapped
        candidate_count = 0;
        for (signals) |signal| {
            candidate_count += @boolToInt(str_contains(signal, b));
        }
        std.debug.assert(candidate_count == 6 or candidate_count == 7);
        if (candidate_count != 6) {
            std.mem.swap(u8, &b, &d);
        }

        // check if e and g need to be swapped
        candidate_count = 0;
        for (signals) |signal| {
            candidate_count += @boolToInt(str_contains(signal, e));
        }
        std.debug.assert(candidate_count == 4 or candidate_count == 7);
        if (candidate_count != 4) {
            std.mem.swap(u8, &e, &g);
        }

        var number: i32 = 0;
        for (outputs) |output| {
            number = number * 10 + str_value(output, a, b, c, d, e, f, g);
        }

        score += number;

        // all values are known
        try stdout.print("c: {c} | f: {c}\n", .{c, f});
        try stdout.print("a: {c}\n", .{a});
        try stdout.print("b: {c} | d: {c}\n", .{b, d});
        try stdout.print("e: {c} | g: {c}\n", .{e, g});
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
        \\acedgfb cdfbe gcdfa fbcad dab cefabd cdfgeb eafb cagedb ab | cdfeb fcadb cdfeb cdbaf
    );
    try expect(score == 5353);
}

test "second example" {
    const score = try process(
        \\ be cfbegad cbdgef fgaecd cgeb fdcge agebfd fecdb fabcd edb | fdgacbe cefdb cefbgd gcbe
        \\ edbfga begcd cbg gc gcadebf fbgde acbgfd abcde gfcbed gfec | fcgedb cgb dgebacf gc
        \\ fgaebd cg bdaec gdafb agbcfd gdcbef bgcad gfac gcb cdgabef | cg cg fdcagb cbg
        \\ fbegcd cbd adcefb dageb afcb bc aefdc ecdab fgdeca fcdbega | efabcd cedba gadfec cb
        \\ aecbfdg fbg gf bafeg dbefa fcge gcbea fcaegb dgceab fcbdga | gecf egdcabf bgf bfgea
        \\ fgeab ca afcebg bdacfeg cfaedg gcfdb baec bfadeg bafgc acf | gebdcfa ecba ca fadegcb
        \\ dbcfg fgd bdegcaf fgec aegbdf ecdfab fbedc dacgb gdcebf gf | cefg dcbef fcge gbcadfe
        \\ bdfegc cbegaf gecbf dfcage bdacg ed bedf ced adcbefg gebcd | ed bcgafe cdgba cbgef
        \\ egadfb cdbfeg cegd fecab cgb gbdefca cg fgcdab egfdb bfceg | gbdfcae bgc cg cgb
        \\ gcafb gcf dcaebfg ecagb gf abcdeg gaef cafbge fdbac fegbdc | fgae cfgab fg bagce
    );
    try expect(score == 61229);
}
