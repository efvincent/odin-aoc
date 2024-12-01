package aoc24

import "core:fmt"

SplitIterator :: struct {
	s:         string,
	cur:       int,
	max_idx:   int,
	delimiter: u8,
}

main :: proc() {
	ans1 := solve_24d01(Part.p1, D01_PUZ)
	ans2 := solve_24d01(Part.p2, D01_PUZ)
	fmt.printfln("Answers to day 1: %s, %s", ans1, ans2)
}
