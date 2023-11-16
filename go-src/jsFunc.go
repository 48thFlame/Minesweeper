package main

import "syscall/js"

func main() {
	done := make(chan struct{})

	js.Global().Set("getGrid", js.FuncOf(getGridJsFunc))
	js.Global().Set("newMines", js.FuncOf(newMinesJsFunc))

	<-done
}

func getGridJsFunc(this js.Value, args []js.Value) any {
	defer doNotPanicPlease()

	rowsNum := args[0].Int()
	colsNum := args[1].Int()
	mines := convertToSlice(args[2])
	flagged := convertToSlice(args[3])
	opened := convertToSlice(args[4])

	return getGrid(rowsNum, colsNum, mines, flagged, opened)
}

func newMinesJsFunc(this js.Value, args []js.Value) any {
	defer doNotPanicPlease()

	rowsNum := args[0].Int()
	colsNum := args[1].Int()
	opened := args[2].Int()

	return newMines(rowsNum, colsNum, opened)
}
