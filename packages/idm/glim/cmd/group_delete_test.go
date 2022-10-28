package cmd

import (
	"testing"

	"github.com/google/uuid"
)

func TestDeleteCmd(t *testing.T) {
	dbPath := uuid.New()
	e := testSetup(t, dbPath.String(), false)
	defer testCleanUp(dbPath.String())

	// Launch testing server
	go func() {
		e.Start(":51013")
	}()

	waitForTestServer(t, ":51013")

	testCases := []CmdTestCase{
		{
			name:           "login successful",
			cmd:            LoginCmd(),
			args:           []string{"--server", "http://127.0.0.1:51013", "--username", "admin", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "new group test",
			cmd:            NewGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51013", "--group", "test", "--description", "test", "--members", "kim,saul"},
			errorMessage:   "",
			successMessage: "Group created\n",
		},
		{
			name:           "new group killers",
			cmd:            NewGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51013", "--group", "killers", "--description", "test", "--members", "charles"},
			errorMessage:   "",
			successMessage: "Group created\n",
		},
		{
			name:           "delete group killers",
			cmd:            DeleteGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51013", "--group", "killers", "--force"},
			errorMessage:   "",
			successMessage: "Group deleted\n",
		},
		{
			name:           "list groups without killers",
			cmd:            ListGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51013", "--json"},
			errorMessage:   "",
			successMessage: `[{"gid":1,"name":"test","description":"test","members":[{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":4,"username":"kim","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"","guac_config_parameters":""}]` + "\n",
		},
		{
			name:           "try to delete non-existent group",
			cmd:            DeleteGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51013", "--group", "killers", "--force"},
			errorMessage:   "group not found",
			successMessage: "",
		},
		{
			name:           "try to delete non-existent group using gid",
			cmd:            DeleteGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51013", "-i", "10", "--force"},
			errorMessage:   "group not found",
			successMessage: "",
		},
		{
			name:           "login successful as kim",
			cmd:            LoginCmd(),
			args:           []string{"--server", "http://127.0.0.1:51013", "--username", "kim", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "try to delete group without permissions",
			cmd:            DeleteGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51013", "-i", "1", "--force"},
			errorMessage:   "user has no proper permissions",
			successMessage: "",
		},
	}

	for _, tc := range testCases {
		runTests(t, tc)
	}
}
