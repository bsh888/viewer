// +build darwin freebsd linux netbsd openbsd

package main

import (
	"fmt"
	"log"
	"syscall"

	"github.com/fvbock/endless"
)

// 开始运行Rest服务
func (s *Server) Run() error {
	handler := NewHandler(s.config)
	defer handler.model.db.Close()

	router := s.InitRouter(handler)

	listen := fmt.Sprintf("%s:%d", s.config.Listen, s.config.Port)
	server := endless.NewServer(listen, router)
	server.BeforeBegin = func(add string) {
		log.Printf("Actual pid is %d\n", syscall.Getpid())
	}
	err := server.ListenAndServe()
	if err != nil {
		log.Println(err)
	}

	return nil

}
