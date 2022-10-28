package cmd

import (
	"testing"

	"github.com/google/uuid"
)

func TestUpdateGroupCmd(t *testing.T) {
	dbPath := uuid.New()
	e := testSetup(t, dbPath.String(), false)
	defer testCleanUp(dbPath.String())

	// Launch testing server
	go func() {
		e.Start(":51015")
	}()

	waitForTestServer(t, ":51015")

	testCases := []CmdTestCase{
		{
			name:           "login successful",
			cmd:            LoginCmd(),
			args:           []string{"--server", "http://127.0.0.1:51015", "--username", "admin", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "new group test",
			cmd:            NewGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51015", "--group", "test", "--description", "test", "--members", "kim,saul"},
			errorMessage:   "",
			successMessage: "Group created\n",
		},
		{
			name:           "update group requires gid or group name",
			cmd:            UpdateGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51015", "--description", "new description"},
			errorMessage:   "you must specify either the group id or name",
			successMessage: "",
		},
		{
			name:           "can't update group using non-existent group name",
			cmd:            UpdateGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51015", "--group", "what"},
			errorMessage:   "group not found",
			successMessage: "",
		},
		{
			name:           "can't update group using non-existent gid",
			cmd:            UpdateGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51015", "--gid", "10"},
			errorMessage:   "group not found",
			successMessage: "",
		},
		{
			name:           "update group description",
			cmd:            UpdateGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51015", "--group", "test", "--description", "new description"},
			errorMessage:   "",
			successMessage: "Group updated\n",
		},
		{
			name:           "group test detail is ok",
			cmd:            ListGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51015", "--gid", "1", "--json"},
			errorMessage:   "",
			successMessage: `{"gid":1,"name":"test","description":"new description","members":[{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":4,"username":"kim","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"","guac_config_parameters":""}` + "\n",
		},
		{
			name:           "add mike as group members",
			cmd:            UpdateGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51015", "--group", "test", "--members", "mike"},
			errorMessage:   "",
			successMessage: "Group updated\n",
		},
		{
			name:           "mike is a new member",
			cmd:            ListGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51015", "--gid", "1", "--json"},
			errorMessage:   "",
			successMessage: `{"gid":1,"name":"test","description":"new description","members":[{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":4,"username":"kim","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":5,"username":"mike","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"","guac_config_parameters":""}` + "\n",
		},
		{
			name:           "replace all members",
			cmd:            UpdateGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51015", "--group", "test", "--members", "mike", "--replace"},
			errorMessage:   "",
			successMessage: "Group updated\n",
		},
		{
			name:           "mike is the only member",
			cmd:            ListGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51015", "--gid", "1", "--json"},
			errorMessage:   "",
			successMessage: `{"gid":1,"name":"test","description":"new description","members":[{"uid":5,"username":"mike","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"","guac_config_parameters":""}` + "\n",
		},
		{
			name:           "login successful as kim",
			cmd:            LoginCmd(),
			args:           []string{"--server", "http://127.0.0.1:51015", "--username", "kim", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "kim can't update group",
			cmd:            UpdateGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:51015", "--group", "test", "--description", "new description"},
			errorMessage:   "user has no proper permissions",
			successMessage: "",
		},
	}

	for _, tc := range testCases {
		runTests(t, tc)
	}
}
