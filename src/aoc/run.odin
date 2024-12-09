package aoc

import "../aoc24"
import "../util"
import "core:fmt"


run :: proc() {
	day_08()
}

day_09 :: proc() {
	data := aoc24.D09_PUZ_EX
	ans1 := aoc24.solve_d09(.p1, data)
	// ans2 := aoc24.solve_d09(.p2, data)
	defer {
		delete(ans1)
		// delete(ans2)
	}
	// fmt.printfln("Answers to day 9: %v, %v", ans1, ans2)
	fmt.printfln("Answers to day 9: %v", ans1)
}

day_08 :: proc() {
	data := aoc24.D08_PUZ
	ans1 := aoc24.solve_d08(.p1, data)
	ans2 := aoc24.solve_d08(.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 8: %s, %s", ans1, ans2)
}

day_07 :: proc() {
	data := aoc24.D07_PUZ
	ans1 := aoc24.solve_d07(.p1, data)
	ans2 := aoc24.solve_d07(.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 7: %s, %s", ans1, ans2)
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
