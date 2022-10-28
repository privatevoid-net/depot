package cmd

import (
	"os"
	"testing"

	"github.com/google/uuid"
)

func prepareUserDeleteTestFiles() error {

	// File with a good CSV file
	f, err := os.Create("/tmp/file1.csv")
	if err != nil {
		return err
	}
	defer f.Close()

	_, err = f.WriteString("uid, username\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`0,saul` + "\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`4,""` + "\n")
	if err != nil {
		return err
	}
	f.Sync()

	// File with no groups
	f, err = os.Create("/tmp/file2.csv")
	if err != nil {
		return err
	}
	defer f.Close()

	_, err = f.WriteString("uid, username\n")
	if err != nil {
		return err
	}
	f.Sync()

	// File with wrong header
	f, err = os.Create("/tmp/file3.csv")
	if err != nil {
		return err
	}
	defer f.Close()

	_, err = f.WriteString("uid, userdsdsname\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`"some","User","",` + "\n")
	if err != nil {
		return err
	}
	f.Sync()

	// File with groups with errors
	f, err = os.Create("/tmp/file4.csv")
	if err != nil {
		return err
	}
	defer f.Close()

	_, err = f.WriteString("uid, username\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`0,""` + "\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`11,""` + "\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`0,"wrong"` + "\n")
	if err != nil {
		return err
	}
	f.Sync()

	return nil
}

func deleteUserDeleteTestingFiles() {
	os.Remove("/tmp/file1.csv")
	os.Remove("/tmp/file2.csv")
	os.Remove("/tmp/file3.csv")
	os.Remove("/tmp/file4.csv")
}

func TestCsvDeleteUsers(t *testing.T) {
	// Prepare test databases and echo testing server
	dbPath := uuid.New()
	e := testSetup(t, dbPath.String(), false)
	defer testCleanUp(dbPath.String())

	err := prepareUserDeleteTestFiles()
	if err != nil {
		t.Fatal("error preparing CSV testing files")
	}
	defer deleteUserDeleteTestingFiles()

	// Launch testing server
	go func() {
		e.Start(":50035")
	}()

	waitForTestServer(t, ":50035")

	testCases := []CmdTestCase{
		{
			name:           "login successful",
			cmd:            LoginCmd(),
			args:           []string{"--server", "http://127.0.0.1:50035", "--username", "admin", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "file not found",
			cmd:            CsvDeleteUsersCmd(),
			args:           []string{"--server", "http://127.0.0.1:50035", "--file", "/tmp/file1"},
			errorMessage:   "can't open CSV file",
			successMessage: "",
		},
		{
			name:           "delete users should be succesful",
			cmd:            CsvDeleteUsersCmd(),
			args:           []string{"--server", "http://127.0.0.1:50035", "--file", "/tmp/file1.csv"},
			errorMessage:   "",
			successMessage: "saul: successfully removed\n\n: successfully removed\n\nRemove from CSV finished!\n",
		},
		{
			name:           "user list should be empty",
			cmd:            ListUserCmd(),
			args:           []string{"--server", "http://127.0.0.1:50035", "--json"},
			errorMessage:   "",
			successMessage: `[{"uid":1,"username":"admin","name":"","firstname":"LDAP","lastname":"administrator","email":"","ssh_public_key":"","jpeg_photo":"","manager":true,"readonly":false,"locked":false},{"uid":2,"username":"search","name":"","firstname":"Read-Only","lastname":"Account","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":true,"locked":false},{"uid":5,"username":"mike","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}]` + "\n",
		},
		{
			name:           "repeat file, users should be skipped",
			cmd:            CsvDeleteUsersCmd(),
			args:           []string{"--server", "http://127.0.0.1:50035", "--file", "/tmp/file1.csv"},
			errorMessage:   "",
			successMessage: "saul: skipped, user not found\n\nUID 4: skipped, user not found\nRemove from CSV finished!\n",
		},
		{
			name:           "file without users",
			cmd:            CsvDeleteUsersCmd(),
			args:           []string{"--server", "http://127.0.0.1:50035", "--file", "/tmp/file2.csv"},
			errorMessage:   "no users where found in CSV file",
			successMessage: "",
		},
		{
			name:           "file with wrong header",
			cmd:            CsvDeleteUsersCmd(),
			args:           []string{"--server", "http://127.0.0.1:50035", "--file", "/tmp/file3.csv"},
			errorMessage:   "wrong header",
			successMessage: "",
		},
		{
			name:           "file with users that have several errors",
			cmd:            CsvDeleteUsersCmd(),
			args:           []string{"--server", "http://127.0.0.1:50035", "--file", "/tmp/file4.csv"},
			errorMessage:   "",
			successMessage: "UID 0: skipped, invalid username and uid\n\nUID 11: skipped, user not found\nwrong: skipped, user not found\n\nRemove from CSV finished!\n",
		},
	}

	for _, tc := range testCases {
		runTests(t, tc)
	}

}
