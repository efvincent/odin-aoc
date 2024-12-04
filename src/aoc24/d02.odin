package aoc24

import "../util"
import conv "core:strconv"
import "core:strings"
import "core:testing"

// this approach uses ~ 9kb statically allocated regardless of
// puzzle size. This means can only handle max 1000 line puzzles
@(private = "file")
Line :: struct {
	count:   u8,
	reports: [8]u8,
}

@(private = "file")
Lines :: struct {
	count: int,
	lines: [1000]Line,
}

@(test)
d02_test_parse :: proc(t: ^testing.T) {
	ans := parse(D02_PUZ_EX)

	testing.expect_value(t, ans.count, 6)
	for idx := 0; idx < ans.count; idx += 1 {
		testing.expect_value(t, ans.lines[idx].count, 5)
	}
}

@(test)
d02_part01_test :: proc(t: ^testing.T) {
	p1 := solve_d02(.p1, D02_PUZ_EX)
	defer delete(p1)
	testing.expect_value(t, p1, "2")
}

@(test)
d02_part02_test :: proc(t: ^testing.T) {
	p2 := solve_d02(.p2, D02_PUZ_EX)
	defer delete(p2)
	testing.expect_value(t, p2, "4")
}

solve_d02 :: proc(part: util.Part, data: string) -> string {
	switch part {
	case .p1:
		return solve1(data)
	case .p2:
		return solve2(data)
	}
	return ""
}

@(private = "file")
parse :: proc(data: string) -> Lines {
	// use the temp allocator (an arena that will be auto-freed at the end of scope)
	// for all of the string allocations that will happen when parsing. Reset
	// to the original allocator at the end of scope
	orig_allocator := context.allocator
	context.allocator = context.temp_allocator
	defer context.allocator = orig_allocator

	raw_lines := strings.split_lines(data)

	lines := Lines {
		count = len(raw_lines),
	}

	for raw_line, rl_idx in raw_lines {
		raw_reports := strings.split(raw_line, " ")
		lines.lines[rl_idx].count = u8(len(raw_reports))
		for raw_report, rr_idx in raw_reports {
			report := u8(conv.atoi(raw_report))
			lines.lines[rl_idx].reports[rr_idx] = report
		}
	}
	return lines
}

@(private = "file")
is_line_safe :: proc(line: Line) -> bool {
	cur := line.reports[0]
	increasing := cur < line.reports[1]
	for idx := u8(1); idx < line.count; idx += 1 {
		next := line.reports[idx]
		if increasing && cur > next || !increasing && cur < next || cur == next do return false
		if (next > cur && next - cur > 3) || (next < cur && cur - next > 3) do return false
		cur = next
	}
	return true
}

@(private = "file")
is_adjusted_line_safe :: proc(line: Line) -> bool {
	if is_line_safe(line) do return true
	adjusted := Line {
		count = line.count - 1,
	}
	for skip_idx := u8(0); skip_idx < line.count; skip_idx += 1 {
		adjusted_idx := u8(0)
		for idx := u8(0); idx < line.count; idx += 1 {
			if idx == skip_idx do idx += 1
			if idx >= line.count do break
			adjusted.reports[adjusted_idx] = line.reports[idx]
			adjusted_idx += 1
		}
		if is_line_safe(adjusted) do return true
	}
	return false
}

@(private = "file")
solve2 :: proc(data: string) -> string {
	lines := parse(data)
	count := 0
	for line_idx := 0; line_idx < lines.count; line_idx += 1 {
		if is_adjusted_line_safe(lines.lines[line_idx]) do count += 1
	}
	return util.to_str(count)
}

@(private = "file")
solve1 :: proc(data: string) -> string {
	lines := parse(data)
	count := 0
	for line_idx := 0; line_idx < lines.count; line_idx += 1 {
		if is_line_safe(lines.lines[line_idx]) do count += 1
	}
	return util.to_str(count)
}
