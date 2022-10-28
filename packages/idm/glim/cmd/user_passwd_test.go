package cmd

import (
	"os"
	"testing"

	"github.com/google/uuid"
)

func TestUserPasswdCmd(t *testing.T) {
	dbPath := uuid.New()
	e := testSetup(t, dbPath.String(), false)
	defer testCleanUp(dbPath.String())

	// Launch testing server
	go func() {
		e.Start(":51009")
	}()

	waitForTestServer(t, ":51009")

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
			args:           []string{"--server", "http://127.0.0.1:51009", "--username", "admin", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "test1 user created",
			cmd:            NewUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51009", "--username", "test1", "--password", "test"},
			errorMessage:   "",
			successMessage: "User created\n",
		},
		{
			name:           "test2 user created",
			cmd:            NewUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:51009", "--username", "test2", "--password", "test"},
			errorMessage:   "",
			successMessage: "User created\n",
		},
		{
			name:           "admin can change test2 password",
			cmd:            UserPasswdCmd(),
			args:           []string{"--server", "http://127.0.0.1:51009", "-i", "4", "--password", "test"},
			errorMessage:   "",
			successMessage: "Password changed\n",
		},
		{
			name:           "admin logout successful",
			cmd:            LogoutCmd(),
			args:           []string{"--server", "http://127.0.0.1:51009"},
			errorMessage:   "",
			successMessage: "Removing login credentials\n",
		},
		{
			name:           "test1 login successful",
			cmd:            LoginCmd(),
			args:           []string{"--server", "http://127.0.0.1:51009", "--username", "test2", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "test1 should not be able to change test2 password",
			cmd:            UserPasswdCmd(),
			args:           []string{"--server", "http://127.0.0.1:51009", "-i", "4", "--password", "test"},
			errorMessage:   "only users with manager role can change other users passwords",
			successMessage: "dswd",
		},
	}

	for _, tc := range testCases {
		runTests(t, tc)
	}
}
