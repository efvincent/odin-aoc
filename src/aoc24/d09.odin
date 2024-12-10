package aoc24

import "../util"
import "core:fmt"
import "core:log"
import "core:math"
import "core:slice"
import "core:strconv"
import conv "core:strconv"
import "core:strings"
import "core:testing"

solve_d09 :: proc(part: util.Part, data: string) -> string {
	switch part {
	case .p1:
		return solve1(data)
	case .p2:
		return solve2(data)
	}
	return ""
}

@(private = "file")
Puz :: struct {
	spaces: []int,
	files:  []File,
}

@(private = "file")
File :: struct {
	id:   int,
	size: int,
}

// init_puz :: proc() -> Puz {
// 	return Puz{spaces = make([dynamic]int), files = make([dynamic]File)}
// }

@(private = "file")
parse :: proc(data: string) -> string {
	file_id := 0
	for idx := 0; idx < (len(data) - 1); idx += 2 {
		f := File {
			id = file_id,
			//size = strconv.atoi(data[idx]),
		}


		file_id += 1
	}
	return ""
}

@(private = "file")
solve2 :: proc(data: string) -> string {
	parse(data)
	return ""
}

@(private = "file")
solve1 :: proc(data: string) -> string {
	parse(data)
	return ""
}
