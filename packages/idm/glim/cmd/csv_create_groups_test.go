package cmd

import (
	"os"
	"testing"

	"github.com/google/uuid"
)

func prepareGroupTestFiles() error {

	// File with a good CSV file
	f, err := os.Create("/tmp/file1.csv")
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

	// File with no groups
	f, err = os.Create("/tmp/file2.csv")
	if err != nil {
		return err
	}
	defer f.Close()

	_, err = f.WriteString("name,description,members,guac_config_protocol,guac_config_parameters\n")
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

	_, err = f.WriteString("name,descrsdiption,members,guac_config_protocol,guac_config_parameters\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`"some","User","",,,` + "\n")
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

	_, err = f.WriteString("name,description,members,guac_config_protocol,guac_config_parameters\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`"","test1","ron",,` + "\n")
	if err != nil {
		return err
	}
	f.Sync()

	return nil
}

func deleteGroupTestingFiles() {
	os.Remove("/tmp/file1.csv")
	os.Remove("/tmp/file2.csv")
	os.Remove("/tmp/file3.csv")
	os.Remove("/tmp/file4.csv")
}

func TestCsvCreateGroups(t *testing.T) {
	// Prepare test databases and echo testing server
	dbPath := uuid.New()
	e := testSetup(t, dbPath.String(), false)
	defer testCleanUp(dbPath.String())

	err := prepareGroupTestFiles()
	if err != nil {
		t.Fatal("error preparing CSV testing files")
	}
	defer deleteGroupTestingFiles()

	// Launch testing server
	go func() {
		e.Start(":50043")
	}()

	waitForTestServer(t, ":50043")

	testCases := []CmdTestCase{
		{
			name:           "login successful",
			cmd:            LoginCmd(),
			args:           []string{"--server", "http://127.0.0.1:50043", "--username", "admin", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "file not found",
			cmd:            CsvCreateGroupsCmd(),
			args:           []string{"--server", "http://127.0.0.1:50043", "--file", "/tmp/file1"},
			errorMessage:   "can't open CSV file",
			successMessage: "",
		},
		{
			name:           "create groups should be succesful",
			cmd:            CsvCreateGroupsCmd(),
			args:           []string{"--server", "http://127.0.0.1:50043", "--file", "/tmp/file1.csv"},
			errorMessage:   "",
			successMessage: "devel: successfully created\nadmins: successfully created\nCreate from CSV finished!\n",
		},
		{
			name:           "group devel detail",
			cmd:            ListGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:50043", "--gid", "1", "--json"},
			errorMessage:   "",
			successMessage: `{"gid":1,"name":"devel","description":"Developers","members":[{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":4,"username":"kim","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"","guac_config_parameters":""}` + "\n",
		},
		{
			name:           "repeat file, groups should be skipped",
			cmd:            CsvCreateGroupsCmd(),
			args:           []string{"--server", "http://127.0.0.1:50043", "--file", "/tmp/file1.csv"},
			errorMessage:   "",
			successMessage: "devel: skipped, group already exists\nadmins: skipped, group already exists\nCreate from CSV finished!\n",
		},
		{
			name:           "file without groups",
			cmd:            CsvCreateGroupsCmd(),
			args:           []string{"--server", "http://127.0.0.1:50043", "--file", "/tmp/file2.csv"},
			errorMessage:   "no groups where found in CSV file",
			successMessage: "",
		},
		{
			name:           "file with wrong header",
			cmd:            CsvCreateGroupsCmd(),
			args:           []string{"--server", "http://127.0.0.1:50043", "--file", "/tmp/file3.csv"},
			errorMessage:   "wrong header",
			successMessage: "",
		},
		{
			name:           "file with groups that have several errors",
			cmd:            CsvCreateGroupsCmd(),
			args:           []string{"--server", "http://127.0.0.1:50043", "--file", "/tmp/file4.csv"},
			errorMessage:   "",
			successMessage: ": skipped, required group name\nCreate from CSV finished!\n",
		},
	}

	for _, tc := range testCases {
		runTests(t, tc)
	}

}
