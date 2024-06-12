package main

import (
	"context"
	"os"

	"github.com/fastly/compute-sdk-go/fsthttp"
)

func main() {
	fsthttp.ServeFunc(ServeHTTP)
}

func ServeHTTP(ctx context.Context, resp fsthttp.ResponseWriter, req *fsthttp.Request) {
	contents, err := os.ReadFile("./localfiles.txt")
	if err != nil {
		resp.Write([]byte(err.Error()))
		resp.WriteHeader(500)
	}
	resp.Header().Set("Content-Type", "text/plain")
	resp.Write(contents)
}
