package aoc24

import "core:fmt"

run :: proc() {
	day_14()
	free_all(context.temp_allocator)
}

all_days :: proc() {
	day_01()
	day_02()
	day_03()
	day_04()
	day_05()
	day_06()
	day_07()
	day_08()
	day_09()
	day_10()
	day_11()
	day_12()
	day_13()
	day_14()
	day_15()
	day_16()
}

day_16 :: proc() {
	data := D16_PUZ
	ans1, ans2 := solve_d16(data)
	fmt.printfln("Answers to day 16: %v, %v", ans1, ans2)
}

day_15 :: proc() {
	data := D15_PUZ
	ans1 := solve_d15(.p1, data)
	ans2 := solve_d15(.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 15: %v, %v", ans1, ans2)
}

day_14 :: proc() {
	data := D14_PUZ
	// ans1 := solve_d14(.p1, data)
	ans2 := solve_d14(.p2, data)
	defer {
		// delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 14: %v", ans2)
	// fmt.printfln("Answers to day 14: %v, %v", ans1, ans2)
}

day_13 :: proc() {
	data := D13_PUZ
	ans1 := solve_d13(.p1, data)
	ans2 := solve_d13(.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 13: %v, %v", ans1, ans2)
}

day_12 :: proc() {
	data := D12_PUZ
	ans1 := solve_d12(.p1, data)
	ans2 := solve_d12(.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 12: %v, %v", ans1, ans2)
}

day_11 :: proc() {
	data := D11_PUZ
	ans1 := solve_d11(.p1, data)
	ans2 := solve_d11(.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 11: %v, %v", ans1, ans2)
}

day_10 :: proc() {
	data := D10_PUZ
	ans1 := solve_d10(.p1, data)
	ans2 := solve_d10(.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 10: %v, %v", ans1, ans2)
}

day_09 :: proc() {
	data := D09_PUZ
	ans1 := solve_d09(.p1, data)
	ans2 := solve_d09(.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 9: %v, %v", ans1, ans2)
}

day_08 :: proc() {
	data := D08_PUZ
	ans1 := solve_d08(.p1, data)
	ans2 := solve_d08(.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 8: %s, %s", ans1, ans2)
}

day_07 :: proc() {
	data := D07_PUZ
	ans1 := solve_d07(.p1, data)
	ans2 := solve_d07(.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 7: %s, %s", ans1, ans2)
}

day_06 :: proc() {
	data := D06_PUZ
	ans1 := solve_d06(.p1, data)
	ans2 := solve_d06(.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 6: %s, %s", ans1, ans2)
}

day_05 :: proc() {
	data := D05_PUZ
	ans1 := solve_d05(.p1, data)
	ans2 := solve_d05(.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 5: %s, %s", ans1, ans2)
}

day_04 :: proc() {
	data := D04_PUZ
	ans1 := solve_d04(.p1, data)
	ans2 := solve_d04(.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 4: %s, %s", ans1, ans2)
}

day_01 :: proc() {
	data := D01_PUZ

	ans1 := solve_d01(.p1, data)
	ans2 := solve_d01(.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 1: %s, %s", ans1, ans2)
}

day_02 :: proc() {
	data := D02_PUZ

	ans1 := solve_d02(.p1, data)
	ans2 := solve_d02(.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 2: %s, %s", ans1, ans2)

}

day_03 :: proc() {
	data := D03_PUZ
	ans1 := solve_d03(.p1, data)
	ans2 := solve_d03(.p2, data)
	defer {
		delete(ans1)
		delete(ans2)
	}
	fmt.printfln("Answers to day 3: %s, %s", ans1, ans2)
}
