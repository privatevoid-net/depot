package cmd

import (
	"os"
	"testing"

	"github.com/google/uuid"
)

func prepareGroupDeleteTestFiles() error {

	// File with new groups file
	f, err := os.Create("/tmp/file0.csv")
	if err != nil {
		return err
	}
	defer f.Close()

	_, err = f.WriteString("name,description,members,guac_config_protocol,guac_config_parameters\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`"devel","Developers","saul,kim",,` + "\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`"admins","Administratos","kim",,` + "\n")
	if err != nil {
		return err
	}
	f.Sync()

	// File with a good CSV file
	f, err = os.Create("/tmp/file1.csv")
	if err != nil {
		return err
	}
	defer f.Close()

	_, err = f.WriteString("gid, name\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`0,"devel"` + "\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`2,""` + "\n")
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

	_, err = f.WriteString("gid, name\n")
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

	_, err = f.WriteString("gid, ndsdame\n")
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

	_, err = f.WriteString("gid, name\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`0,""` + "\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`1,""` + "\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`0,"devel"` + "\n")
	if err != nil {
		return err
	}
	f.Sync()

	return nil
}

func deleteGroupDeleteTestingFiles() {
	os.Remove("/tmp/file0.csv")
	os.Remove("/tmp/file1.csv")
	os.Remove("/tmp/file2.csv")
	os.Remove("/tmp/file3.csv")
	os.Remove("/tmp/file4.csv")
}

func TestCsvDeleteGroups(t *testing.T) {
	// Prepare test databases and echo testing server
	dbPath := uuid.New()
	e := testSetup(t, dbPath.String(), false)
	defer testCleanUp(dbPath.String())

	err := prepareGroupDeleteTestFiles()
	if err != nil {
		t.Fatal("error preparing CSV testing files")
	}
	defer deleteGroupDeleteTestingFiles()

	// Launch testing server
	go func() {
		e.Start(":50034")
	}()

	waitForTestServer(t, ":50034")

	testCases := []CmdTestCase{
		{
			name:           "login successful",
			cmd:            LoginCmd(),
			args:           []string{"--server", "http://127.0.0.1:50034", "--username", "admin", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "file not found",
			cmd:            CsvDeleteGroupsCmd(),
			args:           []string{"--server", "http://127.0.0.1:50034", "--file", "/tmp/file1"},
			errorMessage:   "can't open CSV file",
			successMessage: "",
		},
		{
			name:           "create groups should be succesful",
			cmd:            CsvCreateGroupsCmd(),
			args:           []string{"--server", "http://127.0.0.1:50034", "--file", "/tmp/file0.csv"},
			errorMessage:   "",
			successMessage: "devel: successfully created\nadmins: successfully created\nCreate from CSV finished!\n",
		},
		{
			name:           "delete groups should be succesful",
			cmd:            CsvDeleteGroupsCmd(),
			args:           []string{"--server", "http://127.0.0.1:50034", "--file", "/tmp/file1.csv"},
			errorMessage:   "",
			successMessage: "devel: successfully removed\n\n: successfully removed\n\nRemove from CSV finished!\n",
		},
		{
			name:           "group list should be empty",
			cmd:            ListGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:50034", "--json"},
			errorMessage:   "",
			successMessage: `[]` + "\n",
		},
		{
			name:           "repeat file, groups should be skipped",
			cmd:            CsvDeleteGroupsCmd(),
			args:           []string{"--server", "http://127.0.0.1:50034", "--file", "/tmp/file1.csv"},
			errorMessage:   "",
			successMessage: "devel: skipped, group not found\n\nGID 2: skipped, group not found\nRemove from CSV finished!\n",
		},
		{
			name:           "file without groups",
			cmd:            CsvDeleteGroupsCmd(),
			args:           []string{"--server", "http://127.0.0.1:50034", "--file", "/tmp/file2.csv"},
			errorMessage:   "no groups where found in CSV file",
			successMessage: "",
		},
		{
			name:           "file with wrong header",
			cmd:            CsvDeleteGroupsCmd(),
			args:           []string{"--server", "http://127.0.0.1:50034", "--file", "/tmp/file3.csv"},
			errorMessage:   "wrong header",
			successMessage: "",
		},
		{
			name:           "file with groups that have several errors",
			cmd:            CsvDeleteGroupsCmd(),
			args:           []string{"--server", "http://127.0.0.1:50034", "--file", "/tmp/file4.csv"},
			errorMessage:   "",
			successMessage: "GID 0: skipped, invalid group name and gid\n\nGID 1: skipped, group not found\ndevel: skipped, group not found\n\nRemove from CSV finished!\n",
		},
	}

	for _, tc := range testCases {
		runTests(t, tc)
	}

}
