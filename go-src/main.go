package main

import (
	"fmt"
	"math/rand"
	"syscall/js"
)

func main() {
	done := make(chan struct{})

	js.Global().Set("newGrid", js.FuncOf(newGrid))

	<-done
}

func doNotPanicPlease() {
	r := recover()

	if r != nil {
		fmt.Println("Recovered from", r)
	}
}

// Cells:
// 0..8 = An open cell and its number represents how many mines are around.
// 9 = Mine Cell
// 10 = Closed cell.
// 11 = Flag cell.
type Cell = int

// `newGrid(rows_num, cols_num)` expects 2 args: rows_num and cols_num, both need to be ints.
// Can't return a nested array threw WASM (couldn't figure this one out)
// so returns a 1-D array where the rows are separated by -1
func newGrid(this js.Value, args []js.Value) any {
	defer doNotPanicPlease()

	rows_num := args[0].Int()
	cols_num := args[1].Int()

	grid := make([]any, 0)

	for rowI := 0; rowI < rows_num; rowI++ {
		for colI := 0; colI < cols_num; colI++ {
			cell := rand.Intn(12)

			grid = append(grid, cell)

		}
	}

	return grid
}
