
gosrv/go.mod: gosrv/main.go
		docker-compose exec -u $$(id -u) gosrv \
		    go mod init github.com/littlebenlittle/echo

gosrv/echo/echo.pb.go: proto/echo.proto
		docker run -it --rm -u $$(id -u) \
		    -v $(CURDIR)/proto:/proto \
		    -v $(CURDIR)/gosrv/echo:/build \
			grpc/go:1.0 protoc \
			    --proto_path=/proto \
			    --go_out=plugins=grpc:/build \
				/proto/echo.proto

gocli/echo/echo.pb.go: proto/echo.proto
		docker run -it --rm -u $$(id -u) \
		    -v $(CURDIR)/proto:/proto \
		    -v $(CURDIR)/gocli/echo:/build \
			grpc/go:1.0 protoc \
			    --proto_path=/proto \
			    --go_out=plugins=grpc:/build \
				/proto/echo.proto

pycli/echo/echo_pb2.py: proto/echo.proto
		docker run --rm -u $$(id -u) \
		    -v $(CURDIR)/proto:/proto \
		    -v $(CURDIR)/pycli/echo:/build \
			benlittle6/protoc_python:latest python -m grpc_tools.protoc \
			    --proto_path=/proto \
			    --python_out=/build \
			    --grpc_python_out=/build \
				/proto/echo.proto

.PHONY: proto_clean
proto_clean: 
	rm -rf \
	    gosrv/echo/echo.pb.go \
	    gocli/echo/echo.pb.go \
	   	pycli/echo/echo_pb2.py \
	   	pycli/echo/echo_pb2_grpc.py

.PHONY: proto
proto: gosrv/echo/echo.pb.go gocli/echo/echo.pb.go pycli/echo/echo_pb2.py

.PHONY: tls
tls:
	docker run --rm -u $$(id -u) \
		-v $(CURDIR)/tls:/tls \
	benlittle6/openssl \
	    openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
	        -subj "/C=US/ST=TEST/O=TEST/O=TEST/CN=localhost" \
	        -passout pass:abc123 \
	        -out /tls/srv.crt \
	        -keyout /tls/srv.key
