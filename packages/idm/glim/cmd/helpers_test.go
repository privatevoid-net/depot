package cmd

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"os"
	"testing"
	"time"

	"github.com/antelman107/net-wait-go/wait"
	"github.com/doncicuto/glim/server/api/handlers"
	"github.com/doncicuto/glim/server/db"
	"github.com/doncicuto/glim/server/kv/badgerdb"
	"github.com/doncicuto/glim/types"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"github.com/labstack/gommon/log"
	"github.com/spf13/cobra"
	"github.com/stretchr/testify/assert"
	"gorm.io/gorm"
)

func newTestDatabase(dbPath string) (*gorm.DB, error) {
	var dbInit = types.DBInit{
		AdminPasswd:   "test",
		SearchPasswd:  "test",
		Users:         "saul,kim,mike",
		DefaultPasswd: "test",
		UseSqlite:     true,
	}
	sqlLog := false
	return db.Initialize(fmt.Sprintf("/tmp/%s.db", dbPath), sqlLog, dbInit)
}

func newTestKV(dbPath string) (badgerdb.Store, error) {
	return badgerdb.NewBadgerStore(fmt.Sprintf("/tmp/%s", dbPath))
}

func testSettings(db *gorm.DB, kv types.Store) types.APISettings {
	return types.APISettings{
		DB:                 db,
		KV:                 kv,
		TLSCert:            "",
		TLSKey:             "",
		Address:            "127.0.0.1:1323",
		APISecret:          "secret",
		AccessTokenExpiry:  3600,
		RefreshTokenExpiry: 259200,
		MaxDaysWoRelogin:   7,
	}
}

func testSetup(t *testing.T, dbPath string, guacamole bool) *echo.Echo {
	// New SQLite test database
	db, err := newTestDatabase(dbPath)
	if err != nil {
		t.Fatalf("could not initialize db - %v", err)
	}

	// New BadgerDB test key-value storage
	kv, err := newTestKV(dbPath)
	if err != nil {
		t.Fatalf("could not initialize kv - %v", err)
	}

	settings := testSettings(db, kv)
	settings.Guacamole = guacamole
	e := handlers.EchoServer(settings)
	e.Logger.SetLevel(log.ERROR)
	e.Logger.SetHeader("${time_rfc3339} [Glim] ⇨")
	e.Use(middleware.LoggerWithConfig(middleware.LoggerConfig{
		Format: "${time_rfc3339} [REST] ⇨ ${status} ${method} ${uri} ${remote_ip} ${error}\n",
	}))
	e.Logger.Printf("starting REST API in address %s...", settings.Address)
	return e
}

func testCleanUp(dbPath string) {
	removeDatabase(dbPath)
	removeKV(dbPath)
}

func removeDatabase(dbPath string) {
	os.Remove(fmt.Sprintf("/tmp/%s.db", dbPath))
}

func removeKV(dbPath string) {
	os.RemoveAll(fmt.Sprintf("/tmp/%s", dbPath))
}

type CmdTestCase struct {
	name           string
	cmd            *cobra.Command
	args           []string
	successMessage string
	errorMessage   string
}

func waitForTestServer(t *testing.T, address string) {
	if !wait.New(
		wait.WithProto("tcp"),
		wait.WithWait(200*time.Millisecond),
		wait.WithBreak(50*time.Millisecond),
		wait.WithDeadline(5*time.Second),
		wait.WithDebug(true),
	).Do([]string{address}) {
		t.Fatal("test server is not available")
		return
	}
}

func runTests(t *testing.T, tc CmdTestCase) {
	t.Run(tc.name, func(t *testing.T) {
		b := bytes.NewBufferString("")
		cmd := tc.cmd
		cmd.SetOut(b)
		cmd.SetArgs(tc.args)
		err := cmd.Execute()
		if err != nil {
			assert.Equal(t, tc.errorMessage, err.Error())
		} else {
			if tc.successMessage != "" {
				out, err := ioutil.ReadAll(b)
				if err != nil {
					t.Fatal(err)
				}
				assert.Equal(t, tc.successMessage, string(out))
			}
		}
	})
}
