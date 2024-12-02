package util

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"
import "core:testing"
Part :: enum {
	p1,
	p2,
}

to_str :: proc(v: any) -> string {
	sb := strings.Builder{}
	defer strings.builder_destroy(&sb)
	fmt.sbprint(&sb, v)
	return strings.clone(strings.to_string(sb))
}

TrackingAllocatorState :: struct {
	orig_allocator: mem.Allocator,
	orig_logger:    log.Logger,
	tracker:        mem.Tracking_Allocator,
	console_logger: log.Logger,
}

@(test)
test_to_str :: proc(t: ^testing.T) {
	data := 1
	expected := "1"
	actual := to_str(data)
	defer delete(actual)
	testing.expect_value(t, actual, expected)
}
