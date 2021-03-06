package main

import (
	"database/sql"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	_ "github.com/mattn/go-sqlite3"
	"github.com/spf13/pflag"
	"gopkg.in/yaml.v2"
)

// 设置常量
const banner string = `
MyViewer
`

// 变量
var (
	argConfigFile = pflag.String("config", "./config.yaml", "config file.")
	argVersion    = pflag.Bool("version", false, "The version of MyViewer.")
)

// 定义类型
type (
	Config struct {
		Listen       string `yaml:"listen"`
		Port         int    `yaml:"port"`
		Static       string `yaml:"static"`
		ConfigJs     string `yaml:"configjs"`
		DealPics     string `yaml:"dealpics"`
		DealVideos   string `yaml:"dealvideos"`
		SourcePics   string `yaml:"sourcepics"`
		SourceVideos string `yaml:"sourcevideos"`
		DBFile       string `yaml:"dbfile"`
	}

	Model struct {
		db   *sql.DB
		file string
	}

	Handler struct {
		model *Model
	}

	Server struct {
		config *Config
	}

	Result struct {
		Code int         `json:"code"`
		Msg  string      `json:"msg"`
		Data interface{} `json:"data"`
	}

	FileModel struct {
		ID       int    `json:"id"`
		Path     string `json:"path"`
		Type     string `json:"type"`
		DateTime string `json:"datetime"`
	}
)

// 实例化配置
func NewConfig() *Config {
	return &Config{}
}

// 读取配置文件
func (c *Config) ReadConfigFile(fileName string) error {
	data, err := ioutil.ReadFile(fileName)
	if err != nil {
		return err
	}

	if err := yaml.Unmarshal([]byte(data), c); err != nil {
		return err
	}
	return nil
}

// 写配置文件
func (c *Config) WriteConfigFile() error {
	data, err := yaml.Marshal(c)
	if err != nil {
		return err
	}

	execPath, err := os.Getwd()
	if err != nil {
		return err
	}

	configPath := execPath + "/config.yaml"
	err = ioutil.WriteFile(configPath, data, 0755)
	if err != nil {
		return err
	}

	return nil
}

// 实例化Rest服务
func NewServer(c *Config) *Server {
	return &Server{
		config: c,
	}
}

// 跨域Option支持中间件
func Cors() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, PUT, POST, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, Accept, Origin, Cache-Control, X-Requested-With, User-Agent, jweToken")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")

		origin := c.Request.Header.Get("Origin")
		c.Writer.Header().Set("Access-Control-Allow-Origin", origin)

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
		}
	}
}

// 初始化路由规则
func (s *Server) InitRouter(h *Handler) *gin.Engine {
	router := gin.Default()

	// router.Use(gin.Logger())
	// router.Use(gin.Recovery())

	router.Use(Cors())

	router.Static("/viewer", s.config.Static)
	router.StaticFile("/config.js", s.config.ConfigJs)
	router.Static("/css", s.config.Static+"/css")
	router.Static("/img", s.config.Static+"/img")
	router.Static("/js", s.config.Static+"/js")
	router.Static("/dealpics", s.config.DealPics)
	router.Static("/dealvideos", s.config.DealVideos)
	router.Static("/sourcepics", s.config.SourcePics)
	router.Static("/sourcevideos", s.config.SourceVideos)
	router.StaticFile("/favicon.ico", s.config.Static+"/favicon.ico")

	dbGroup := router.Group("/db")
	dbGroup.Use()
	{
		dbGroup.GET("/table", h.HandlerDBTable)
		dbGroup.GET("/data", h.HandlerDBData(s.config))
	}

	apiGroup := router.Group("/api")
	apiGroup.Use()
	{
		apiGroup.GET("/config", h.HandlerApiConfig(s.config))
		apiGroup.GET("/filelist", h.HandlerApiFileList)
	}

	return router
}

// 打开数据库
func (m *Model) OpenDB() (err error) {
	db, err := sql.Open("sqlite3", m.file)
	if err != nil {
		return err
	}
	m.db = db
	return nil
}

// 初始化数据库表
func (m *Model) InitDB() (err error) {
	sql := `
DROP TABLE IF EXISTS file;
`
	stmt, err := m.db.Prepare(sql)
	if err != nil {
		return err
	}

	stmt.Exec()

	sql = `
CREATE TABLE IF NOT EXISTS file (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    path VARCHAR(128) NOT NULL DEFAULT '',
    type CHAR(1) NOT NULL DEFAULT ('P'),
    datetime DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00'
);
`
	stmt, err = m.db.Prepare(sql)
	if err != nil {
		return err
	}

	stmt.Exec()

	return nil
}

// 初始化数据库数据
func (m *Model) InsertFileData(path, myType, datetime string) (id int64, err error) {
	//插入数据
	stmt, err := m.db.Prepare("INSERT INTO file(path, type, datetime) values(?,?,?)")
	if err != nil {
		return id, err
	}

	res, err := stmt.Exec(path, myType, datetime)
	if err != nil {
		return id, err
	}

	id, err = res.LastInsertId()
	if err != nil {
		return id, err
	}

	return id, nil
}

// 获取文件列表
func (m *Model) FileList(myType, minDateTime, maxDateTime string, page, perPage int) (fileModels []FileModel, count int, err error) {
	// 条件查询
	where := "1 = 1"
	if myType != "" {
		where = fmt.Sprintf("%s AND type = '%s'", where, myType)
	}
	if minDateTime != "" {
		where = fmt.Sprintf("%s AND datetime >= '%s'", where, minDateTime)
	}
	if maxDateTime != "" {
		where = fmt.Sprintf("%s AND datetime <= '%s'", where, maxDateTime)
	}

	// 获取总数
	sql := fmt.Sprintf("SELECT COUNT(id) AS count FROM file WHERE %s LIMIT 1", where)
	// fmt.Println(sql)
	row, err := m.db.Query(sql)
	if err != nil {
		return fileModels, count, err
	}
	defer row.Close()

	for row.Next() {
		row.Scan(&count)
	}

	if page <= 0 {
		page = 1
	}
	if perPage <= 0 {
		perPage = 10
	}
	from := (page - 1) * perPage
	sql = fmt.Sprintf("SELECT id, path, type, datetime FROM file WHERE %s ORDER BY datetime DESC LIMIT %d, %d", where, from, perPage)
	// fmt.Println(sql)

	row, err = m.db.Query(sql)
	if err != nil {
		return fileModels, count, err
	}
	defer row.Close()

	for row.Next() {
		var id int
		var path string
		var myType string
		var dateTime string
		row.Scan(&id, &path, &myType, &dateTime)
		fileModel := FileModel{
			ID:       id,
			Path:     path,
			Type:     myType,
			DateTime: dateTime,
		}
		fileModels = append(fileModels, fileModel)
	}

	return fileModels, count, nil
}

// 初始化Handler入口
func NewHandler(c *Config) *Handler {
	model := &Model{
		file: c.DBFile,
	}
	model.OpenDB()

	return &Handler{
		model: model,
	}
}

// 获取配置信息
func (h *Handler) HandlerApiConfig(config *Config) gin.HandlerFunc {
	fn := func(c *gin.Context) {
		r := Result{
			Code: 10000,
			Msg:  "",
		}

		ip, err := getClientIp()
		if err != nil {
			r.Code = 10003
			r.Msg = err.Error()
			c.JSON(http.StatusOK, r)
			return
		}

		type Res struct {
			Host         string `json:"host"`
			DealPics     string `json:"dealpics"`
			DealVideos   string `json:"dealvideos"`
			SourcePics   string `json:"sourcepics"`
			SourceVideos string `json:"sourcevideos"`
		}
		host := fmt.Sprintf("http://%s:%d/", ip, config.Port)
		res := Res{
			Host:         host,
			DealPics:     host + "dealpics/",
			DealVideos:   host + "dealvideos/",
			SourcePics:   host + "sourcepics/",
			SourceVideos: host + "sourcevideos/",
		}

		r.Data = res
		c.JSON(http.StatusOK, r)
	}

	return gin.HandlerFunc(fn)
}

// 初始化数据库操作入口
func (h *Handler) HandlerDBTable(c *gin.Context) {
	r := Result{
		Code: 10000,
		Msg:  "",
	}

	err := h.model.InitDB()
	if err == nil {
		c.JSON(http.StatusOK, r)
		return
	}

	r.Code = 10001
	r.Msg = err.Error()
	c.JSON(http.StatusOK, r)
	return
}

func (h *Handler) doDBData(dir, myType string, w http.ResponseWriter) error {
	return filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		name := info.Name()
		if !info.IsDir() && !strings.HasPrefix(name, ".") {
			first := len(dir) + 1
			names := strings.Split(name, "_")
			if len(names) < 2 {
				errStr := fmt.Sprintf("文件非法 Path:%s", path)
				log.Println(errStr)
				return nil
			}
			dateField := names[0]
			timeField := names[1]
			if len(dateField) != 8 || len(timeField) < 6 {
				errStr := fmt.Sprintf("文件时间非法: Path:%s Date:%s Time:%s", path, dateField, timeField)
				log.Println(errStr)
				return nil
			}
			if name[len(name)-4:] != ".jpg" {
				return nil
			}
			datetime := fmt.Sprintf("%s-%s-%s %s:%s:%s", dateField[:4], dateField[4:6], dateField[6:8], timeField[:2], timeField[2:4], timeField[4:6])
			id, err := h.model.InsertFileData(path[first:], myType, datetime)
			if err != nil {
				log.Println(err.Error())
				return nil
			}

			w.Write([]byte(fmt.Sprintf("<font face=\"verdana\" color=\"green\">ID:%d Path:%s</font><br/>\n", id, path)))
			w.(http.Flusher).Flush()

		}
		return nil
	})
}

func (h *Handler) HandlerDBData(config *Config) gin.HandlerFunc {
	fn := func(c *gin.Context) {
		r := Result{
			Code: 10000,
			Msg:  "",
		}

		w := c.Writer
		header := w.Header()
		header.Set("Transfer-Encoding", "chunked")
		header.Set("Content-Type", "text/html")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("<html><body>\n"))
		w.(http.Flusher).Flush()

		h.doDBData(config.DealPics, "P", w)
		h.doDBData(config.DealVideos, "V", w)

		w.Write([]byte("</body></html>\n"))
		w.(http.Flusher).Flush()

		c.JSON(http.StatusOK, r)
		return
	}

	return gin.HandlerFunc(fn)
}

// 文件列表接口
func (h *Handler) HandlerApiFileList(c *gin.Context) {
	r := Result{
		Code: 10000,
		Msg:  "",
	}

	myType := c.Query("type")
	minDateTime := c.Query("min-date-time")
	maxDateTime := c.Query("max-date-time")
	page := c.Query("page")
	perPage := c.Query("per-page")
	pageInt, _ := strconv.Atoi(page)
	perPageInt, _ := strconv.Atoi(perPage)

	fileModels, count, err := h.model.FileList(myType, minDateTime, maxDateTime, pageInt, perPageInt)

	type Res struct {
		Count int         `json:"count"`
		List  []FileModel `json:"list"`
	}
	res := Res{
		Count: count,
		List:  fileModels,
	}

	r.Data = res
	if err != nil {
		r.Code = 10002
		r.Msg = err.Error()
		c.JSON(http.StatusOK, r)
		return
	}

	c.JSON(http.StatusOK, r)
	return
}

// 入口主函数
func main() {
	log.Print(banner)

	runtime.GOMAXPROCS(runtime.NumCPU())

	if *argVersion {
		return
	}

	if len(*argConfigFile) == 0 {
		log.Fatalln("Must use a config file")
	}

	config := NewConfig()
	err := config.ReadConfigFile(*argConfigFile)
	if err != nil {
		log.Fatalf("Read config file error:%v\n", err.Error())
	}

	ip, err := getClientIp()
	if err == nil {
		log.Printf("访问地址: http://%s:%d/viewer/\n", ip, config.Port)
	}

	server := NewServer(config)
	server.Run()
}

func getClientIp() (string, error) {
	addrs, err := net.InterfaceAddrs()

	if err != nil {
		return "", err
	}

	for _, address := range addrs {
		// 检查ip地址判断是否回环地址
		if ipnet, ok := address.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				return ipnet.IP.String(), nil
			}

		}
	}

	return "", errors.New("Can not find the client ip address!")
}
