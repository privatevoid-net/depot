package cmd

import (
	"testing"

	"github.com/google/uuid"
)

func TestUpdateGuacamoleGroupCmd(t *testing.T) {
	dbPath := uuid.New()
	e := testSetup(t, dbPath.String(), true)
	defer testCleanUp(dbPath.String())

	// Launch testing server
	go func() {
		e.Start(":56022")
	}()

	waitForTestServer(t, ":56022")

	testCases := []CmdTestCase{
		{
			name:           "login successful",
			cmd:            LoginCmd(),
			args:           []string{"--server", "http://127.0.0.1:56022", "--username", "admin", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "new group test",
			cmd:            NewGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:56022", "--group", "test", "--description", "test", "--members", "kim,saul", "--guacamole-protocol", "ssh", "--guacamole-parameters", "host=192.168.1.1,port=22"},
			errorMessage:   "",
			successMessage: "Group created\n",
		},
		{
			name:           "guacamole group updated",
			cmd:            UpdateGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:56022", "--group", "test", "--description", "test", "--members", "kim,saul", "--guacamole-protocol", "vnc", "--guacamole-parameters", "host=192.168.1.1,port=22,password=secret"},
			errorMessage:   "",
			successMessage: "Group updated\n",
		},
		{
			name:           "guacamole group can be updated again",
			cmd:            UpdateGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:56022", "--group", "test", "--description", "test", "--members", "kim,saul", "--guacamole-parameters", "host=192.168.1.1,port=22,password=secret"},
			errorMessage:   "",
			successMessage: "Group updated\n",
		},
		{
			name:           "new group test2",
			cmd:            NewGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:56022", "--group", "test2", "--description", "test", "--members", "kim,saul"},
			errorMessage:   "",
			successMessage: "Group created\n",
		},
		{
			name:           "guacamole group can't be updated",
			cmd:            UpdateGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:56022", "--group", "test2", "--description", "test", "--members", "kim,saul", "--guacamole-parameters", "host=192.168.1.1,port=22,password=secret"},
			errorMessage:   "Apache Guacamole config protocol is required",
			successMessage: "",
		},
	}

	for _, tc := range testCases {
		runTests(t, tc)
	}
}
