package handlers

import (
	"github.com/doncicuto/glim/types"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	echoSwagger "github.com/swaggo/echo-swagger"
	"gorm.io/gorm"
)

// EchoServer - TODO command
// @title Glim REST API
// @version 1.0
// @description Glim REST API for login/logout, user and group operations. Users and groups require a Bearer Token (JWT) that you can retrieve using login. Please use the project's README for full information about how you can use this token with Swagger.
// @contact.name Miguel Cabrerizo
// @contact.url https://github.com/doncicuto/glim/issues
// @contact.email support@sologitops.com
// @license.name Apache 2.0
// @license.url http://www.apache.org/licenses/LICENSE-2.0.html
// @BasePath /v1
// @securityDefinitions.apikey Bearer
// @in header
// @name Authorization
type Handler struct {
	DB        *gorm.DB
	KV        types.Store
	Guacamole bool
}

func EchoServer(settings types.APISettings) *echo.Echo {
	// New Echo framework server
	e := echo.New()
	e.HideBanner = true
	e.HidePort = true

	// Initialize handler
	blacklist := settings.KV
	h := &Handler{DB: settings.DB, KV: blacklist, Guacamole: settings.Guacamole}

	// Routes
	v1 := e.Group("v1")
	v1.POST("/login", func(c echo.Context) error {
		return h.Login(c, settings)
	})
	v1.POST("/login/refresh_token", func(c echo.Context) error {
		return h.Refresh(c, settings)
	})
	v1.DELETE("/login/refresh_token", func(c echo.Context) error {
		return h.Logout(c, settings)
	})
	v1.GET("/guacamole", func(c echo.Context) error {
		return h.GuacamoleSupport(c)
	})
	v1.GET("/healthz", func(c echo.Context) error {
		return h.Healthz(c)
	})
	v1.GET("/readyz", func(c echo.Context) error {
		return h.Readyz(c)
	})

	u := v1.Group("/users")
	u.Use(middleware.JWT([]byte(settings.APISecret)))
	u.GET("", h.FindAllUsers, IsBlacklisted(blacklist), IsReader(settings.DB))
	u.POST("", h.SaveUser, IsBlacklisted(blacklist), IsManager)
	u.GET("/:uid", h.FindUserByID, IsBlacklisted(blacklist), IsReader(settings.DB))
	u.GET("/:username/uid", h.FindUIDFromUsername, IsBlacklisted(blacklist), IsReader(settings.DB))
	u.PUT("/:uid", h.UpdateUser, IsBlacklisted(blacklist), IsUpdater)
	u.DELETE("/:uid", h.DeleteUser, IsBlacklisted(blacklist), IsManager)
	u.POST("/:uid/passwd", h.Passwd, IsBlacklisted(blacklist))

	g := v1.Group("/groups")
	g.Use(middleware.JWT([]byte(settings.APISecret)))
	g.GET("", h.FindAllGroups, IsBlacklisted(blacklist), IsReader(settings.DB))
	g.POST("", h.SaveGroup, IsBlacklisted(blacklist), IsManager)
	g.GET("/:gid", h.FindGroupByID, IsBlacklisted(blacklist), IsReader(settings.DB))
	g.GET("/:group/gid", h.FindGIDFromGroupName, IsBlacklisted(blacklist), IsReader(settings.DB))
	g.PUT("/:gid", h.UpdateGroup, IsBlacklisted(blacklist), IsManager)
	g.DELETE("/:gid", h.DeleteGroup, IsBlacklisted(blacklist), IsManager)
	g.POST("/:gid/members", h.AddGroupMembers, IsBlacklisted(blacklist), IsManager)
	g.DELETE("/:gid/members", h.RemoveGroupMembers, IsBlacklisted(blacklist), IsManager)

	e.GET("/swagger/*", echoSwagger.WrapHandler)

	return e
}
