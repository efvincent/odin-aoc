package aoc

import "core:fmt"
import "core:strings"

to_str :: proc(v: any) -> string {
	sb := strings.Builder{}
	defer strings.builder_destroy(&sb)
	fmt.sbprint(&sb, v)
	return strings.to_string(sb)
}
