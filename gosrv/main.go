
package main

import (
	"io"
	"os"
	"log"
	"fmt"
	"net"
	"context"

	"github.com/littlebenlittle/echo/echo"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
)

type server struct {
	echo.EchoServer
}

func (srv *server) UnaryEcho(_ context.Context, msg *echo.Message) (*echo.Message, error) {
	return msg, nil
}

func (srv *server) StreamEcho(stream echo.Echo_StreamEchoServer) error {
	log.Println("stream request received...")
	for {
		msg, err := stream.Recv()
		if err == io.EOF {
			log.Println("received EOF: exiting...")
			return nil
		}
		if err != nil {
			log.Printf("receive error: %v", err)
			return nil
		}
		stream.Send(msg)
	}
}

func parseEnv() (map[string]string) {
	pass := true
	m := make(map[string]string)
	for _, k := range []string{
		"PORT",
		"CERTFILE",
		"KEYFILE",
	} {
		v := os.Getenv(k)
		if v == "" {
			pass = false
			log.Printf("%s not set", k)
		} else {
			m[k] = v
		}
	}
	if !pass {
		log.Fatal("cannot start due to the above errors")
	}
	return m
}

func main() {
	srv := server{}
	env := parseEnv()
	lis, err := net.Listen("tcp", fmt.Sprintf(":%s", env["PORT"]))
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	creds, err := credentials.NewServerTLSFromFile(
		env["CERTFILE"],
		env["KEYFILE"],
	)
	if err != nil {
		log.Fatalf("failed to create credentials: %v", err)
	}
	s := grpc.NewServer(grpc.Creds(creds))
	log.Printf("starting server on localhost:%s ...", env["PORT"])
	echo.RegisterEchoServer(s, &srv)
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
