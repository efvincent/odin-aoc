package aoc24

import "../util"
import "core:math"
import "core:slice"
import conv "core:strconv"
import "core:strings"
import "core:testing"

@(test)
d01_part01_test :: proc(t: ^testing.T) {
	p1 := solve_d01(.p1, D01_PUZ_EX)
	testing.expect_value(t, p1, "11")
}

@(test)
d01_part02_test :: proc(t: ^testing.T) {
	p2 := solve_d01(.p2, D01_PUZ_EX)
	testing.expect_value(t, p2, "31")
}

solve_d01 :: proc(part: util.Part, data: string) -> string {
	switch part {
	case .p1:
		return solve1(data)
	case .p2:
		return solve2(data)
	}
	return ""
}

@(private = "file")
parse :: proc(data: string) -> ([]int, []int) {
	lines := strings.split_lines(data)
	line_count := len(lines)
	left := make([]int, line_count)
	right := make([]int, line_count)

	for line, idx in lines {
		parts := strings.split(line, "   ")
		left[idx] = conv.atoi(parts[0])
		right[idx] = conv.atoi(parts[1])
	}
	return left, right
}

@(private = "file")
solve2 :: proc(data: string) -> string {
	orig_allocator := context.allocator
	context.allocator = context.temp_allocator
	defer context.allocator = orig_allocator

	left, right := parse(data)
	in_right := make(map[int]int)
	counts := make(map[int]int)

	for n in right {
		in_right[n] = in_right[n] + 1
	}

	tot := 0
	for l in left {
		c, found := in_right[l]
		if found {
			sub := l * c
			tot += sub
		}

	}
	return util.to_str(tot)
}

@(private = "file")
solve1 :: proc(data: string) -> string {
	orig_allocator := context.allocator
	context.allocator = context.temp_allocator
	defer context.allocator = orig_allocator

	left, right := parse(data)

	slice.sort(left)
	slice.sort(right)

	tot := 0
	for _, idx in left {
		diff := math.abs(left[idx] - right[idx])
		tot += diff
	}

	return util.to_str(tot)
}
