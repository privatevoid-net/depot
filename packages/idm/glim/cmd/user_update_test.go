package cmd

import (
	"testing"

	"github.com/google/uuid"
)

func TestUserUpdateCmd(t *testing.T) {
	dbPath := uuid.New()
	e := testSetup(t, dbPath.String(), false)
	defer testCleanUp(dbPath.String())

	// Launch testing server
	go func() {
		e.Start(":51011")
	}()

	waitForTestServer(t, ":51011")

	testCases := []CmdTestCase{
		{
			name:           "login successful",
			cmd:            LoginCmd(),
			args:           []string{"--server", "http://127.0.0.1:51011", "--username", "admin", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "wrong email",
			cmd:            UpdateUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51011", "--username", "mike", "--email", "test"},
			errorMessage:   "email should have a valid format",
			successMessage: "",
		},
		{
			name:           "update mike's email",
			cmd:            UpdateUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51011", "--username", "mike", "--email", "mike@example.org"},
			errorMessage:   "",
			successMessage: "User updated\n",
		},
		{
			name:           "mike has now email",
			cmd:            ListUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51011", "-i", "5", "--json"},
			errorMessage:   "",
			successMessage: `{"uid":5,"username":"mike","name":"","firstname":"","lastname":"","email":"mike@example.org","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}` + "\n",
		},
		{
			name:           "update mike's firtsname and lastname using uid",
			cmd:            UpdateUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51011", "-i", "5", "--firstname", "Mike", "--lastname", "Ehrmantraut"},
			errorMessage:   "",
			successMessage: "User updated\n",
		},
		{
			name:           "mike has first name and last name",
			cmd:            ListUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51011", "-i", "5", "--json"},
			errorMessage:   "",
			successMessage: `{"uid":5,"username":"mike","name":"Mike Ehrmantraut","firstname":"Mike","lastname":"Ehrmantraut","email":"mike@example.org","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}` + "\n",
		},
		{
			name:           "update expects uid or username",
			cmd:            UpdateUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51011"},
			errorMessage:   "you must specify either the user account id or a username",
			successMessage: "",
		},
		{
			name:           "mike should be manager",
			cmd:            UpdateUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51011", "-i", "5", "--manager"},
			errorMessage:   "",
			successMessage: "User updated\n",
		},
		{
			name:           "mike is manager indeed",
			cmd:            ListUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51011", "-i", "5", "--json"},
			errorMessage:   "",
			successMessage: `{"uid":5,"username":"mike","name":"Mike Ehrmantraut","firstname":"Mike","lastname":"Ehrmantraut","email":"mike@example.org","ssh_public_key":"","jpeg_photo":"","manager":true,"readonly":false,"locked":false}` + "\n",
		},
		{
			name:           "mike can't be manager and readonly at the same time",
			cmd:            UpdateUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51011", "-i", "5", "--manager", "--readonly"},
			errorMessage:   "a Glim account cannot be both manager and readonly at the same time",
			successMessage: "",
		},
		{
			name:           "login as saul successful",
			cmd:            LoginCmd(),
			args:           []string{"--server", "http://127.0.0.1:51011", "--username", "saul", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "saul can't update mike's account",
			cmd:            UpdateUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51011", "-i", "5", "--firstname", "Mike", "--lastname", "Ehrmantraut"},
			errorMessage:   "user has no proper permissions",
			successMessage: "",
		},
	}

	for _, tc := range testCases {
		runTests(t, tc)
	}
}
