// +build windows

package main

import (
	"fmt"
)

// 开始运行Rest服务
func (s *Server) Run() error {
	handler := NewHandler(s.config)
	defer handler.model.db.Close()

	router := s.InitRouter(handler)

	listen := fmt.Sprintf("%s:%d", s.config.Listen, s.config.Port)

	router.Run(listen)

	return nil

}
