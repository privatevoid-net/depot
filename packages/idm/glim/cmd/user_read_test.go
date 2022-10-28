package cmd

import (
	"os"
	"testing"

	"github.com/google/uuid"
)

func TestUserReadCmd(t *testing.T) {
	dbPath := uuid.New()
	e := testSetup(t, dbPath.String(), false)
	defer testCleanUp(dbPath.String())

	// Launch testing server
	go func() {
		e.Start(":51010")
	}()

	waitForTestServer(t, ":51010")

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
			args:           []string{"--server", "http://127.0.0.1:51010", "--username", "admin", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "list initial users",
			cmd:            ListUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51010", "--json"},
			errorMessage:   "",
			successMessage: `[{"uid":1,"username":"admin","name":"","firstname":"LDAP","lastname":"administrator","email":"","ssh_public_key":"","jpeg_photo":"","manager":true,"readonly":false,"locked":false},{"uid":2,"username":"search","name":"","firstname":"Read-Only","lastname":"Account","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":true,"locked":false},{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":4,"username":"kim","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":5,"username":"mike","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}]` + "\n",
		},
		{
			name:           "test1 user created",
			cmd:            NewUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51010", "--username", "test1", "--password", "test"},
			errorMessage:   "",
			successMessage: "User created\n",
		},
		{
			name:           "list users including test1",
			cmd:            ListUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51010", "--json"},
			errorMessage:   "",
			successMessage: `[{"uid":1,"username":"admin","name":"","firstname":"LDAP","lastname":"administrator","email":"","ssh_public_key":"","jpeg_photo":"","manager":true,"readonly":false,"locked":false},{"uid":2,"username":"search","name":"","firstname":"Read-Only","lastname":"Account","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":true,"locked":false},{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":4,"username":"kim","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":5,"username":"mike","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":6,"username":"test1","name":" ","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}]` + "\n",
		},
		{
			name:           "test1 user deleted",
			cmd:            DeleteUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51010", "--username", "test1", "--force"},
			errorMessage:   "",
			successMessage: "User account deleted\n",
		},
		{
			name:           "list users after test1 deleted",
			cmd:            ListUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51010", "--json"},
			errorMessage:   "",
			successMessage: `[{"uid":1,"username":"admin","name":"","firstname":"LDAP","lastname":"administrator","email":"","ssh_public_key":"","jpeg_photo":"","manager":true,"readonly":false,"locked":false},{"uid":2,"username":"search","name":"","firstname":"Read-Only","lastname":"Account","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":true,"locked":false},{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":4,"username":"kim","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":5,"username":"mike","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}]` + "\n",
		},
		{
			name:           "user 120 does not exist",
			cmd:            ListUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51010", "-i", "120", "--json"},
			errorMessage:   "user not found",
			successMessage: "",
		},
		{
			name:           "user 5 exists",
			cmd:            ListUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51010", "-i", "5", "--json"},
			errorMessage:   "",
			successMessage: `{"uid":5,"username":"mike","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}` + "\n",
		},
		{
			name:           "username mike exists",
			cmd:            ListUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51010", "-u", "mike", "--json"},
			errorMessage:   "",
			successMessage: `{"uid":5,"username":"mike","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}` + "\n",
		},
		{
			name:           "test1 user created",
			cmd:            NewUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51010", "--username", "test1", "--password", "test"},
			errorMessage:   "",
			successMessage: "User created\n",
		},
		{
			name:           "login as test1 successful",
			cmd:            LoginCmd(),
			args:           []string{"--server", "http://127.0.0.1:51010", "--username", "test1", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "list users with test1 privileges",
			cmd:            ListUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51010", "--json"},
			errorMessage:   "",
			successMessage: `{"uid":6,"username":"test1","name":" ","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}` + "\n",
		},
		{
			name:           "test1 can't see mikes info",
			cmd:            ListUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51010", "-u", "mike", "--json"},
			errorMessage:   "user has no proper permissions",
			successMessage: "",
		},
	}

	for _, tc := range testCases {
		runTests(t, tc)
	}
}
