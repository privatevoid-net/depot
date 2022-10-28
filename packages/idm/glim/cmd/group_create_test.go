package cmd

import (
	"testing"

	"github.com/google/uuid"
)

func TestNewGroupCmd(t *testing.T) {
	dbPath := uuid.New()
	e := testSetup(t, dbPath.String(), false)
	defer testCleanUp(dbPath.String())

	// Launch testing server
	go func() {
		e.Start(":51021")
	}()

	waitForTestServer(t, ":51021")

	testCases := []CmdTestCase{
		{
			name:           "login successful",
			cmd:            LoginCmd(),
			args:           []string{"--server", "http://127.0.0.1:51021", "--username", "admin", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "new group test",
			cmd:            NewGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51021", "--group", "test", "--description", "test", "--members", "kim,saul"},
			errorMessage:   "",
			successMessage: "Group created\n",
		},
		{
			name:           "group already exists",
			cmd:            NewGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51021", "--group", "test", "--description", "test", "--members", "kim,saul"},
			errorMessage:   "group already exists",
			successMessage: "",
		},
		{
			name:           "new group killers",
			cmd:            NewGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51021", "--group", "killers", "--description", "test", "--members", "charles"},
			errorMessage:   "",
			successMessage: "Group created\n",
		},
		{
			name:           "login successful as kim",
			cmd:            LoginCmd(),
			args:           []string{"--server", "http://127.0.0.1:51021", "--username", "kim", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "kim can't add new group",
			cmd:            NewGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51021", "--group", "killers", "--description", "test", "--members", "charles"},
			errorMessage:   "user has no proper permissions",
			successMessage: "",
		},
	}

	for _, tc := range testCases {
		runTests(t, tc)
	}
}
