#+private file
package aoc24

import "../util"
import "core:math"
import "core:slice"
import conv "core:strconv"
import "core:strings"

@(private = "package")
solve_d01 :: proc(part: util.Part, data: string) -> string {
	switch part {
	case .p1:
		return solve1(data)
	case .p2:
		return solve2(data)
	}
	return ""
}

parse :: proc(data: string) -> ([]int, []int) {
	lines := strings.split_lines(data, allocator = context.temp_allocator)
	line_count := len(lines)
	left := make([]int, line_count, allocator = context.temp_allocator)
	right := make([]int, line_count, allocator = context.temp_allocator)

	for line, idx in lines {
		parts := strings.split(line, "   ", allocator = context.temp_allocator)
		left[idx] = conv.atoi(parts[0])
		right[idx] = conv.atoi(parts[1])
	}
	return left, right
}

solve2 :: proc(data: string) -> string {

	left, right := parse(data)

	in_right := make(map[int]int, allocator = context.temp_allocator)

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

solve1 :: proc(data: string) -> string {
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
