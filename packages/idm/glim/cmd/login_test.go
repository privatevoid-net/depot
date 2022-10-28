package cmd

import (
	"bytes"
	"io/ioutil"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

func TestLoginCmd(t *testing.T) {
	dbPath := uuid.New()
	e := testSetup(t, dbPath.String(), false)
	defer testCleanUp(dbPath.String())

	// Launch testing server
	go func() {
		e.Start(":51005")
	}()

	waitForTestServer(t, ":51005")

	cmd := LoginCmd()

	t.Run("can't connect with server", func(t *testing.T) {
		cmd.SetArgs([]string{"--server", "http://127.0.0.1:1923", "--username", "admin", "--password", "tess"})
		err := cmd.Execute()
		if err != nil {
			assert.Contains(t, err.Error(), "can't connect with Glim")
		}
	})

	t.Run("username is required", func(t *testing.T) {
		cmd.SetArgs([]string{"--server", "http://127.0.0.1:51005", "--username", ""})
		err := cmd.Execute()
		if err != nil {
			assert.Equal(t, "non-null username required", err.Error())
		}
	})

	t.Run("wrong username or password", func(t *testing.T) {
		cmd.SetArgs([]string{"--server", "http://127.0.0.1:51005", "--username", "admin", "--password", "tess"})
		err := cmd.Execute()
		if err != nil {
			assert.Equal(t, "wrong username or password", err.Error())
		}
	})

	t.Run("login successful", func(t *testing.T) {
		b := bytes.NewBufferString("")
		cmd.SetOut(b)
		cmd.SetArgs([]string{"--server", "http://127.0.0.1:51005", "--username", "admin", "--password", "test"})
		err := cmd.Execute()
		if err == nil {
			out, err := ioutil.ReadAll(b)
			if err != nil {
				t.Fatal(err)
			}
			assert.Equal(t, "Login succeeded\n", string(out))
		}
	})
}
