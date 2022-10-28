package cmd

import (
	"testing"

	"github.com/google/uuid"
)

func TestUserCreateCmd(t *testing.T) {
	dbPath := uuid.New()
	e := testSetup(t, dbPath.String(), false)
	defer testCleanUp(dbPath.String())

	// Launch testing server
	go func() {
		e.Start(":51007")
	}()

	waitForTestServer(t, ":51007")

	testCases := []CmdTestCase{
		{
			name:           "login successful",
			cmd:            LoginCmd(),
			args:           []string{"--server", "http://127.0.0.1:51007", "--username", "admin", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "wrong email for new user",
			cmd:            NewUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51007", "--username", "test", "--password", "test", "--email", "wrongemail"},
			errorMessage:   "email should have a valid format",
			successMessage: "",
		},
		{
			name:           "user can't have both manager and readonly roles",
			cmd:            NewUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51007", "--username", "test", "--password", "test", "--manager", "--readonly"},
			errorMessage:   "a Glim account cannot be both manager and readonly at the same time",
			successMessage: "",
		},
		{
			name:           "user created",
			cmd:            NewUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51007", "--username", "test", "--password", "test"},
			errorMessage:   "",
			successMessage: "User created\n",
		},
		{
			name:           "user already exists",
			cmd:            NewUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51007", "--username", "test", "--password", "test"},
			errorMessage:   "user already exists",
			successMessage: "",
		},
	}

	for _, tc := range testCases {
		runTests(t, tc)
	}
}
