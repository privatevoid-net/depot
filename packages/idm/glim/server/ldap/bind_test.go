package ldap

import (
	"net"
	"testing"
	"time"

	ldapClient "github.com/go-ldap/ldap"
	"github.com/google/uuid"
)

func TestBindOperation(t *testing.T) {
	dbPath := uuid.New()
	l, settings := testSetup(t, dbPath.String(), false, "127.0.0.1:60000")
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

	waitForTestServer(t, "127.0.0.1:60000")

	// Create an Ldap connection
	c, err := net.Dial("tcp", "127.0.0.1:60000")
	if err != nil {
		t.Fatalf("error connecting to localhost tcp: %v", err)
	}
	conn := ldapClient.NewConn(c, false)
	conn.SetTimeout(3000 * time.Millisecond)
	conn.Start()
	defer conn.Close()

	// Test cases
	testCases := []BindTestCase{
		{
			name:     "Bind successful",
			username: "uid=saul,ou=Users,dc=example,dc=org",
			password: "test",
			conn:     conn,
		},
		{
			name:         "Wrong password",
			username:     "uid=saul,ou=Users,dc=example,dc=org",
			password:     "test1",
			conn:         conn,
			errorMessage: `LDAP Result Code 49 "Invalid Credentials": `,
		},
		{
			name:         "Wrong user",
			username:     "uid=test,ou=Users,dc=example,dc=org",
			password:     "test1",
			conn:         conn,
			errorMessage: `LDAP Result Code 50 "Insufficient Access Rights": `,
		},
		{
			name:         "Empty password not allowed",
			username:     "uid=saul,ou=Users,dc=example,dc=org",
			password:     "",
			conn:         conn,
			errorMessage: `LDAP Result Code 206 "Empty password not allowed by the client": ldap: empty password not allowed by the client`,
		},
		{
			name:         "Wrong domain",
			username:     "uid=saul,ou=Users,dc=example,dc=com",
			password:     "test1",
			conn:         conn,
			errorMessage: `LDAP Result Code 49 "Invalid Credentials": `,
		},
		{
			name:         "Anonymous bind not allowed",
			username:     "",
			password:     "",
			conn:         conn,
			errorMessage: `LDAP Result Code 206 "Empty password not allowed by the client": ldap: empty password not allowed by the client`,
		},
	}

	for _, tc := range testCases {
		runBindTests(t, tc)
	}
}
