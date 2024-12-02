package aoc23

import "../aoc"
import "../util"
import "core:log"
import "core:strconv"
import "core:strings"
import "core:testing"

D01_PUZ_EX :: `1abc2
pqr3stu8vwx
a1b2c3d4e5f
treb7uchet`


D01_PUZ_EX2 :: `two1nine
eightwothree
abcone2threexyz
xtwone3four
4nineeightseven2
zoneight234
7pqrstsixteen`


@(test)
d01_test_part1 :: proc(t: ^testing.T) {
	p1 := solve_d01(.p1, D01_PUZ_EX)
	defer delete(p1)
	testing.expect_value(t, p1, "142")
}

// @(test)
d01_test_part2 :: proc(t: ^testing.T) {
	p2 := solve_d01(.p2, D01_PUZ_EX2)
	defer delete(p2)
	testing.expect_value(t, p2, "281")
}

solve_d01 :: proc(part: util.Part, data: string) -> string {
	switch part {
	case .p1:
		return solve1(data)
	case .p2:
		return solve2(data)
	}
	return string{}
}

@(private)
solve1 :: proc(data: string) -> string {
	lines := strings.split_lines(data)
	defer delete(lines)
	tot := 0
	for line in lines {
		tot += decode_line1(line)
	}
	return util.to_str(tot)
}

@(private)
decode_line1 :: proc(line: string) -> int {
	ans: [2]u8
	for c in line {
		char := u8(c)
		if char >= '0' && char <= '9' {
			ans[0] = char - '0'
			break
		}
	}
	for idx := len(line) - 1; idx >= 0; idx -= 1 {
		char := line[idx]
		if char >= '0' && char <= '9' {
			ans[1] = char - '0'
			break
		}
	}
	return int((ans[0] * 10) + ans[1])
}

@(private)
solve2 :: proc(data: string) -> string {
	return util.to_str(0)
}
