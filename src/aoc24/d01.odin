package aoc24

import "../aoc"
import "core:math"
import "core:slice"
import conv "core:strconv"
import "core:strings"
import "core:testing"

YEAR :: "2024"
D01_PUZ_EX :: `3   4
4   3
2   5
1   3
3   9
3   3`


@(test)
d01_part01_test :: proc(t: ^testing.T) {
	p1 := solve_24d01(.p1, D01_PUZ_EX)
	testing.expect_value(t, p1, "11")
}

@(test)
d02_part02_test :: proc(t: ^testing.T) {
	p2 := solve_24d01(.p2, D01_PUZ_EX)
	testing.expect_value(t, p2, "31")
}

solve_24d01 :: proc(part: Part, data: string) -> string {
	switch part {
	case .p1:
		return solve1(data)
	case .p2:
		return solve2(data)
	}
	return ""
}

@(private)
parse :: proc(data: string) -> ([]int, []int) {
	lines := strings.split_lines(data)
	defer delete(lines)
	line_count := len(lines)
	left := make([]int, line_count)
	right := make([]int, line_count)

	for line, idx in lines {
		parts := strings.split(line, "   ")
		left[idx] = conv.atoi(parts[0])
		right[idx] = conv.atoi(parts[1])
		defer delete(parts)
	}
	return left, right
}

@(private)
solve2 :: proc(data: string) -> string {
	left, right := parse(data)
	defer {
		delete(left)
		delete(right)
	}
	in_right := make(map[int]int)
	counts := make(map[int]int)

	defer {
		delete(in_right)
		delete(counts)
	}

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
	return aoc.to_str(tot)
}

@(private)
solve1 :: proc(data: string) -> string {

	left, right := parse(data)
	defer {
		delete(left)
		delete(right)
	}

	slice.sort(left)
	slice.sort(right)

	tot := 0
	for _, idx in left {
		diff := math.abs(left[idx] - right[idx])
		tot += diff
	}

	return aoc.to_str(tot)
}
