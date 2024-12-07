package aoc

import "../aoc24"
import "../util"
import "core:fmt"
import "core:log"
import "core:os"

run :: proc() {
	day_06()
}

day_06 :: proc() {
	data := aoc24.D06_PUZ
	ans1 := aoc24.solve_d06(.p1, data)
	ans2 := aoc24.solve_d06(.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 6: %s, %s", ans1, ans2)
}
day_05 :: proc() {
	data := aoc24.D05_PUZ
	ans1 := aoc24.solve_d05(.p1, data)
	ans2 := aoc24.solve_d05(.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 5: %s, %s", ans1, ans2)
}

day_04 :: proc() {
	data := aoc24.D04_PUZ
	ans1 := aoc24.solve_d04(.p1, data)
	ans2 := aoc24.solve_d04(.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 4: %s, %s", ans1, ans2)
}

day_01 :: proc() {
	data := aoc24.D01_PUZ

	ans1 := aoc24.solve_d01(util.Part.p1, data)
	ans2 := aoc24.solve_d01(util.Part.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 1: %s, %s", ans1, ans2)
}

day_02 :: proc() {
	data := aoc24.D02_PUZ

	ans1 := aoc24.solve_d02(util.Part.p1, data)
	ans2 := aoc24.solve_d02(util.Part.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 2: %s, %s", ans1, ans2)

}

day_03 :: proc() {
	data := aoc24.D03_PUZ
	ans1 := aoc24.solve_d03(util.Part.p1, data)
	ans2 := aoc24.solve_d03(util.Part.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 3: %s, %s", ans1, ans2)
}
