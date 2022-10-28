package cmd

import (
	"os"
	"testing"

	"github.com/google/uuid"
)

func TestGroupReadCmd(t *testing.T) {
	dbPath := uuid.New()
	e := testSetup(t, dbPath.String(), false)
	defer testCleanUp(dbPath.String())

	// Launch testing server
	go func() {
		e.Start(":51012")
	}()

	waitForTestServer(t, ":51012")

	// Get token path
	tokenPath, err := AuthTokenPath()
	if err != nil {
		t.Fatalf("could not get AuthTokenPath - %v", err)
	}
	os.Remove(tokenPath)

	testCases := []CmdTestCase{
		{
			name:           "login successful",
			cmd:            LoginCmd(),
			args:           []string{"--server", "http://127.0.0.1:51012", "--username", "admin", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "list initial groups",
			cmd:            ListGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51012", "--json"},
			errorMessage:   "",
			successMessage: `[]` + "\n",
		},
		{
			name:           "test group created",
			cmd:            NewGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51012", "--group", "test", "--description", "test", "--members", "saul,mike"},
			errorMessage:   "",
			successMessage: "Group created\n",
		},
		{
			name:           "list current groups",
			cmd:            ListGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51012", "--json"},
			errorMessage:   "",
			successMessage: `[{"gid":1,"name":"test","description":"test","members":[{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":5,"username":"mike","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"","guac_config_parameters":""}]` + "\n",
		},
		{
			name:           "group test detail",
			cmd:            ListGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51012", "--gid", "1", "--json"},
			errorMessage:   "",
			successMessage: `{"gid":1,"name":"test","description":"test","members":[{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":5,"username":"mike","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"","guac_config_parameters":""}` + "\n",
		},
		{
			name:           "login successful as kim",
			cmd:            LoginCmd(),
			args:           []string{"--server", "http://127.0.0.1:51012", "--username", "kim", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "kim can't get details about groups",
			cmd:            ListGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51012", "--json"},
			errorMessage:   "user has no proper permissions",
			successMessage: "",
		},
		{
			name:           "kim can't get details about groups using ls",
			cmd:            ListGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51012", "ls", "--json"},
			errorMessage:   "user has no proper permissions",
			successMessage: "",
		},
		{
			name:           "kim can't get details about specific group",
			cmd:            ListGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51012", "ls", "--gid", "3", "--json"},
			errorMessage:   "user has no proper permissions",
			successMessage: "",
		},
	}

	for _, tc := range testCases {
		runTests(t, tc)
	}
}
