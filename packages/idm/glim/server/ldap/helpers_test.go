package ldap

import (
	"fmt"
	"net"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/antelman107/net-wait-go/wait"
	"github.com/doncicuto/glim/models"
	"github.com/doncicuto/glim/server/db"
	"github.com/doncicuto/glim/types"
	ldapClient "github.com/go-ldap/ldap"
	"github.com/stretchr/testify/assert"
	"gorm.io/gorm"
)

func addMembers(db *gorm.DB, group *models.Group, members string) error {
	for _, member := range strings.Split(members, ",") {
		user := new(models.User)
		err := db.Model(&models.User{}).Where("username = ?", member).Take(&user).Error
		if err == nil {
			// Append association
			err = db.Model(&group).Association("Members").Append(user)
			if err != nil {
				return err
			}
		}
	}
	return nil
}

func addGroup(db *gorm.DB, name string, description string, members string) error {
	g := models.Group{}
	g.Name = &name
	g.Description = &description
	err := db.Create(&g).Error
	if err != nil {
		return err
	}
	addMembers(db, &g, members)
	return nil
}

func newTestDatabase(dbPath string) (*gorm.DB, error) {
	var dbInit = types.DBInit{
		AdminPasswd:   "test",
		SearchPasswd:  "test",
		Users:         "saul,kim,mike",
		DefaultPasswd: "test",
		UseSqlite:     true,
	}
	sqlLog := false
	newDb, err := db.Initialize(fmt.Sprintf("/tmp/%s.db", dbPath), sqlLog, dbInit)
	if err != nil {
		return nil, err
	}

	// Create group test
	err = addGroup(newDb, "test", "Test", "saul,kim")
	if err != nil {
		return nil, err
	}

	// Create group test2
	err = addGroup(newDb, "test2", "Test2", "kim")
	if err != nil {
		return nil, err
	}
	return newDb, nil
}

func testSettings(db *gorm.DB, addr string) types.LDAPSettings {
	return types.LDAPSettings{
		DB:          db,
		TLSDisabled: true,
		Address:     addr,
		Domain:      "dc=example,dc=org",
	}
}

func testSetup(t *testing.T, dbPath string, guacamole bool, addr string) (net.Listener, types.LDAPSettings) {
	// New SQLite test database
	db, err := newTestDatabase(dbPath)
	if err != nil {
		t.Fatalf("could not initialize db - %v", err)
	}

	settings := testSettings(db, addr)
	settings.Guacamole = guacamole

	var l net.Listener
	l, err = net.Listen("tcp", addr)
	if err != nil {
		t.Fatalf("could not initialize socket - %v", err)
	}
	return l, settings
}

func testCleanUp(dbPath string) {
	removeDatabase(dbPath)
}

func removeDatabase(dbPath string) {
	os.Remove(fmt.Sprintf("/tmp/%s.db", dbPath))
}

type BindTestCase struct {
	conn         *ldapClient.Conn
	name         string
	username     string
	password     string
	errorMessage string
}

type SearchTestCase struct {
	conn         *ldapClient.Conn
	name         string
	baseDN       string
	scope        int
	sizeLimit    int
	timeLimit    int
	filter       string
	attributes   []string
	controls     []ldapClient.Control
	numEntries   int
	errorMessage string
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

func runBindTests(t *testing.T, tc BindTestCase) {
	t.Run(tc.name, func(t *testing.T) {
		err := tc.conn.Bind(tc.username, tc.password)
		if err != nil {
			assert.Equal(t, tc.errorMessage, fmt.Sprintf("%v", err.Error()))
		} else {
			if tc.errorMessage != "" {
				t.Fatal(fmt.Errorf("error was expected"))
			}
		}
	})
}

func runSearchTests(t *testing.T, tc SearchTestCase) {
	t.Run(tc.name, func(t *testing.T) {
		searchRequest := ldapClient.NewSearchRequest(tc.baseDN, tc.scope, ldapClient.DerefAlways, tc.sizeLimit, tc.timeLimit, false, tc.filter, tc.attributes, tc.controls)
		sr, err := tc.conn.Search(searchRequest)
		if err != nil {
			assert.Equal(t, tc.errorMessage, fmt.Sprintf("%v", err.Error()))
		} else {
			if tc.errorMessage != "" {
				t.Fatal(fmt.Errorf("error was expected"))
			} else {
				assert.Equal(t, tc.numEntries, len(sr.Entries))
			}
		}
	})
}
