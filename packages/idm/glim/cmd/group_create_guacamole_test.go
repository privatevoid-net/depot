package cmd

import (
	"testing"

	"github.com/google/uuid"
)

func TestNewGuacamoleGroupCmd(t *testing.T) {
	dbPath := uuid.New()
	e := testSetup(t, dbPath.String(), true)
	defer testCleanUp(dbPath.String())

	// Launch testing server
	go func() {
		e.Start(":56021")
	}()

	waitForTestServer(t, ":56021")

	testCases := []CmdTestCase{
		{
			name:           "login successful",
			cmd:            LoginCmd(),
			args:           []string{"--server", "http://127.0.0.1:56021", "--username", "admin", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "new group test",
			cmd:            NewGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:56021", "--group", "test", "--description", "test", "--members", "kim,saul", "--guacamole-protocol", "ssh", "--guacamole-parameters", "host=192.168.1.1,port=22"},
			errorMessage:   "",
			successMessage: "Group created\n",
		},
		{
			name:           "guacamole protocol is required if parameters are set",
			cmd:            NewGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:56021", "--group", "wrong", "--description", "test", "--members", "kim,saul", "--guacamole-parameters", "host=192.168.1.1,port=22"},
			errorMessage:   "Apache Guacamole config protocol is required",
			successMessage: "",
		},
	}

	for _, tc := range testCases {
		runTests(t, tc)
	}
}
