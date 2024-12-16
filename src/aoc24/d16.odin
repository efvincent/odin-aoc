package aoc24

import "../util"
import "core:fmt"
import "core:slice"
import conv "core:strconv"
import "core:strings"

solve_dxx :: proc(part: util.Part, data: string) -> string {
	switch part {
	case .p1:
		return solve1(data)
	case .p2:
		return solve2(data)
	}
	return ""
}

@(private = "file")
parse :: proc(data: string) -> string {
	raw_lines := strings.split_lines(data)

	return ""
}

@(private = "file")
solve2 :: proc(data: string) -> string {
	return ""
}

@(private = "file")
solve1 :: proc(data: string) -> string {
	return ""
}
