package ldap

import (
	"net"
	"testing"
	"time"

	ldapClient "github.com/go-ldap/ldap"
	"github.com/google/uuid"
)

func TestSearchOperation(t *testing.T) {
	dbPath := uuid.New()
	l, settings := testSetup(t, dbPath.String(), false, "127.0.0.1:60001")
	defer testCleanUp(dbPath.String())

	// Launch testing servers
	go func() {
		for {
			// Accept new connections
			c, err := l.Accept()
			if err != nil {
				return
			}
			// Handle our server connection
			go handleConnection(c, settings)
		}
	}()

	waitForTestServer(t, "127.0.0.1:60001")

	// Create an Ldap connection
	c, err := net.Dial("tcp", "127.0.0.1:60001")
	if err != nil {
		t.Fatalf("error connecting to localhost tcp: %v", err)
	}
	conn := ldapClient.NewConn(c, false)
	conn.SetTimeout(3000 * time.Millisecond)
	conn.Start()
	defer conn.Close()

	// Bind
	err = conn.Bind("cn=admin,dc=example,dc=org", "test")
	if err != nil {
		t.Fatalf("error in bind operation: %v", err)
	}

	// Test cases
	testCases := []SearchTestCase{
		{
			name:       "Search users successful",
			conn:       conn,
			baseDN:     "ou=Users,dc=example,dc=org",
			scope:      ldapClient.ScopeWholeSubtree,
			filter:     "(objectclass=*)",
			attributes: []string{},
			controls:   nil,
			numEntries: 4,
		},
		{
			name:       "Search groups successful",
			conn:       conn,
			baseDN:     "ou=Groups,dc=example,dc=org",
			scope:      ldapClient.ScopeWholeSubtree,
			filter:     "(objectclass=*)",
			attributes: []string{},
			controls:   nil,
			numEntries: 3,
		},
		{
			name:         "Wrong base",
			conn:         conn,
			baseDN:       "ou=Users,dc=example,dc=com",
			scope:        ldapClient.ScopeWholeSubtree,
			filter:       "(objectclass=*)",
			attributes:   []string{},
			controls:     nil,
			numEntries:   0,
			errorMessage: `LDAP Result Code 32 "No Such Object": `,
		},
	}

	for _, tc := range testCases {
		runSearchTests(t, tc)
	}
}
