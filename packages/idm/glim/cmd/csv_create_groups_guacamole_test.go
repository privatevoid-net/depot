package cmd

import (
	"os"
	"testing"

	"github.com/google/uuid"
)

func prepareGroupGuacamoleTestFiles() error {

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
	_, err = f.WriteString(`"programmers","Developers","saul,kim","vnc","host=localhost"` + "\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`"managers","Administratos","kim","ssh","host=localhost"` + "\n")
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

	_, err = f.WriteString("name,descriptddion,membdsders,guac_condsdsfig_protocol,guac_config_parameters\n")
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

	_, err = f.WriteString("name,description,members,guac_config_protocol,guac_config_parameters\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`"","test1","ron","",""` + "\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`"test4","test1","kim","","port=22"` + "\n")
	if err != nil {
		return err
	}
	f.Sync()

	return nil
}

func deleteGroupGuacamoleTestingFiles() {
	os.Remove("/tmp/file1.csv")
	os.Remove("/tmp/file2.csv")
	os.Remove("/tmp/file3.csv")
	os.Remove("/tmp/file4.csv")
}

func TestCsvCreateGuacamoleGroups(t *testing.T) {
	// Prepare test databases and echo testing server
	dbPath := uuid.New()
	guacamoleEnabled := true
	e := testSetup(t, dbPath.String(), guacamoleEnabled) // guacamole <- true
	defer testCleanUp(dbPath.String())

	err := prepareGroupGuacamoleTestFiles()
	if err != nil {
		t.Fatal("error preparing CSV testing files")
	}
	defer deleteGroupGuacamoleTestingFiles()

	// Launch testing server
	go func() {
		e.Start(":50033")
	}()

	waitForTestServer(t, ":50033")

	testCases := []CmdTestCase{
		{
			name:           "login successful",
			cmd:            LoginCmd(),
			args:           []string{"--server", "http://127.0.0.1:50033", "--username", "admin", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "file not found",
			cmd:            CsvCreateGroupsCmd(),
			args:           []string{"--server", "http://127.0.0.1:50033", "--file", "/tmp/file1"},
			errorMessage:   "can't open CSV file",
			successMessage: "",
		},
		{
			name:           "create groups should be succesful",
			cmd:            CsvCreateGroupsCmd(),
			args:           []string{"--server", "http://127.0.0.1:50033", "--file", "/tmp/file1.csv"},
			errorMessage:   "",
			successMessage: "programmers: successfully created\nmanagers: successfully created\nCreate from CSV finished!\n",
		},
		{
			name:           "group devel detail",
			cmd:            ListGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:50033", "--gid", "1", "--json"},
			errorMessage:   "",
			successMessage: `{"gid":1,"name":"programmers","description":"Developers","members":[{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":4,"username":"kim","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false}],"guac_config_protocol":"vnc","guac_config_parameters":"host=localhost"}` + "\n",
		},
		{
			name:           "repeat file, groups should be skipped",
			cmd:            CsvCreateGroupsCmd(),
			args:           []string{"--server", "http://127.0.0.1:50033", "--file", "/tmp/file1.csv"},
			errorMessage:   "",
			successMessage: "programmers: skipped, group already exists\nmanagers: skipped, group already exists\nCreate from CSV finished!\n",
		},
		{
			name:           "file without groups",
			cmd:            CsvCreateGroupsCmd(),
			args:           []string{"--server", "http://127.0.0.1:50033", "--file", "/tmp/file2.csv"},
			errorMessage:   "no groups where found in CSV file",
			successMessage: "",
		},
		{
			name:           "file with wrong header",
			cmd:            CsvCreateGroupsCmd(),
			args:           []string{"--server", "http://127.0.0.1:50033", "--file", "/tmp/file3.csv"},
			errorMessage:   "wrong header",
			successMessage: "",
		},
		{
			name:           "file with groups that have several errors",
			cmd:            CsvCreateGroupsCmd(),
			args:           []string{"--server", "http://127.0.0.1:50033", "--file", "/tmp/file4.csv"},
			errorMessage:   "",
			successMessage: ": skipped, required group name\ntest4: skipped, Apache Guacamole config protocol is required\nCreate from CSV finished!\n",
		},
	}

	for _, tc := range testCases {
		runTests(t, tc)
	}

}
