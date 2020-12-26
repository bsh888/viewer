export GO111MODULE=on

DISTDIR:="$(shell pwd)/../viewer"
T:=$(shell mkdir -p $(DISTDIR)/bin)

all: build

build: mac

mac:
	cd backend && go mod tidy && go build -ldflags "-w -s" -o $(DISTDIR)/bin/viewer-mac ./

amd:
	cd backend && go mod tidy && xgo --targets=linux/amd64 -v -x -ldflags "-w -s" -out viewer-amd64 ./ && mv viewer-amd64-linux-amd64 $(DISTDIR)/bin/viewer-amd64

arm:
	cd backend && go mod tidy && xgo --targets=linux/arm64 -v -x -ldflags "-w -s" -out viewer-arm64 ./ && mv viewer-arm64-linux-arm64 $(DISTDIR)/bin/viewer-arm64

win:
	cd backend && go mod tidy && xgo --targets=windows/amd64 -v -x -ldflags "-w -s -extldflags=-fno-PIC" -out viewer.exe ./ && mv viewer.exe-windows-4.0-amd64.exe $(DISTDIR)/bin/viewer.exe

dev:
	cd frontend && yarn serve

static:
	cd frontend && yarn build && rm -rf $(DISTDIR)/static && mv dist $(DISTDIR)/static

clean:
	rm -rf $(DISTDIR)

# test:
# 	cd backend && go test ./go/... -race

run:
	/bin/cp -rpf backend/config.yaml $(DISTDIR)/bin && /bin/cp -rpf backend/config.js $(DISTDIR)/static && cd $(DISTDIR)/bin && ./viewer-mac


