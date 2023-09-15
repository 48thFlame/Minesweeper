package main

import (
	"fmt"
	"syscall/js"
)

func main() {
	done := make(chan struct{})
	js.Global().Set("add", js.FuncOf(add))
	<-done
}

func add(this js.Value, args []js.Value) interface{} {
	defer doNotPanicPlease()

	a := args[0].Float()
	b := args[1].Float()

	return a + b
}

func doNotPanicPlease() {
	r := recover()
	if r != nil {
		fmt.Println("Recovered from", r)
	}
}
