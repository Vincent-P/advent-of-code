const std = @import("std");
const expect = std.testing.expect;
const allocator = std.heap.page_allocator;

const Board = struct {
    numbers: [5][5]i32 = [_][5]i32{ undefined, undefined, undefined, undefined, undefined },
    marked: [5][5]bool = [_][5]bool{ [_]bool{false} ** 5, [_]bool{false} ** 5, [_]bool{false} ** 5, [_]bool{false} ** 5, [_]bool{false} ** 5 },
    has_won: bool = false,
};

const Result = struct {
    score: i32 = 0,
};

pub fn process(input: []const u8) !Result {
    var numbers = std.ArrayList(i32).init(allocator);
    defer numbers.deinit();

    var boards = std.ArrayList(Board).init(allocator);
    defer boards.deinit();

    var lines = std.mem.split(u8, input, "\n");

    // Read the numbers
    var number_iter = std.mem.tokenize(u8, lines.next().?, ",\n");
    while (true) {
        const number_str = number_iter.next() orelse break;
        const number = try std.fmt.parseInt(i32, number_str, 10);
        try numbers.append(number);
    }

    // Read the boards
    var board_numbers = std.mem.tokenize(u8, lines.rest(), " \n");
    outer: while (true) {
        var board = Board{};
        var i_row: usize = 0;
        while (i_row < 5) : (i_row += 1) {
            var i_col: usize = 0;
            while (i_col < 5) : (i_col += 1) {
                const number_str = board_numbers.next() orelse break :outer;
                board.numbers[i_row][i_col] = try std.fmt.parseInt(i32, number_str, 10);
            }
        }
        try boards.append(board);
    }

    // Mark each number
    var result = Result{};
    for (numbers.items) |mark| {
        for (boards.items) |*board| {
            // Apply the current mark
            for (board.*.numbers) |row, i_row| {
                for (row) |number, i_col| {
                    const is_marked = board.*.marked[i_row][i_col];
                    if (is_marked == false and number == mark) {
                        board.*.marked[i_row][i_col] = true;
                    }
                }
            }

            // Check for win
            var won = board.*.has_won;
            var i: usize = 0;
            while (won == false and i < 5) : (i += 1) {
                var row_marked = true;
                var i_inner: usize = 0;
                while (i_inner < 5) : (i_inner += 1) {
                    //  Check all lines
                    if (board.*.marked[i][i_inner] == false) {
                        row_marked = false;
                        break;
                    }
                }
                i_inner = 0;
                var col_marked = true;
                while (i_inner < 5) : (i_inner += 1) {
                    // Check all columns
                    if (board.*.marked[i_inner][i] == false) {
                        col_marked = false;
                        break;
                    }
                }

                if (row_marked or col_marked) {
                    won = true;
                }
            }

            if (board.*.has_won != won and won) {
                board.*.has_won = won;
                result.score = 0;

                for (board.*.numbers) |row, i_row| {
                    for (row) |number, i_col| {
                        if (board.*.marked[i_row][i_col] == false) {
                            result.score += number;
                        }
                    }
                }

                result.score = mark * result.score;
            }
        }
    }

    const stdout = std.io.getStdOut().writer();
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
        \\7,4,9,5,11,17,23,2,0,14,21,24,10,16,13,6,15,25,12,22,18,20,8,19,3,26,1
        \\
        \\22 13 17 11  0
        \\ 8  2 23  4 24
        \\21  9 14 16  7
        \\ 6 10  3 18  5
        \\ 1 12 20 15 19
        \\
        \\ 3 15  0  2 22
        \\ 9 18 13 17  5
        \\19  8  7 25 23
        \\20 11 10 24  4
        \\14 21 16 12  6
        \\
        \\14 21 17 24  4
        \\10 16 15  9 19
        \\18  8 23 26 20
        \\22 11 13  6  5
        \\2  0 12  3  7
    );

    try expect(result.score == 1924);
}
