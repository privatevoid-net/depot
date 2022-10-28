package cmd

import (
	"os"
	"testing"

	"github.com/google/uuid"
)

func prepareTestFiles() error {

	// File with a good CSV file
	f, err := os.Create("/tmp/file1.csv")
	if err != nil {
		return err
	}
	defer f.Close()

	_, err = f.WriteString("username,firstname,lastname,email,password,ssh_public_key,jpeg_photo,manager,readonly,locked,groups\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`"gumball","Gumball","Watterson","gumbal@example.org","test",,,true,false,false,"test"` + "\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`"anais","Anais","Watterson","anais@example.org",,,,false,false,false,"test"` + "\n")
	if err != nil {
		return err
	}
	f.Sync()

	// File with no users
	f, err = os.Create("/tmp/file2.csv")
	if err != nil {
		return err
	}
	defer f.Close()

	_, err = f.WriteString("username,firstname,lastname,email,password,ssh_public_key,jpeg_photo,manager,readonly,locked,groups\n")
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

	_, err = f.WriteString("username,firstname,rerer,ssh_public_key,jpeg_photo,manager,readonly,locked,groups\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`"some","User","Wrong","test@example.org",,,,false,false,false,` + "\n")
	if err != nil {
		return err
	}
	f.Sync()

	// File with users with errors
	f, err = os.Create("/tmp/file4.csv")
	if err != nil {
		return err
	}
	defer f.Close()

	_, err = f.WriteString("username,firstname,lastname,email,password,ssh_public_key,jpeg_photo,manager,readonly,locked,groups\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`"test1","Anais","Watterson","anais@example.org",,,,true,true,false,"test"` + "\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`"test1","Anais","Watterson","anais",,,,false,false,false,"test"` + "\n")
	if err != nil {
		return err
	}
	_, err = f.WriteString(`"test1","Anais","Watterson","anais@example.org",,,"/tmp/nonexistent",false,false,false,"test"` + "\n")
	if err != nil {
		return err
	}
	f.Sync()

	return nil
}

func deleteTestingFiles() {
	os.Remove("/tmp/file1.csv")
	os.Remove("/tmp/file2.csv")
	os.Remove("/tmp/file3.csv")
	os.Remove("/tmp/file4.csv")
}

func TestCsvCreateUsers(t *testing.T) {
	// Prepare test databases and echo testing server
	dbPath := uuid.New()
	e := testSetup(t, dbPath.String(), false)
	defer testCleanUp(dbPath.String())

	err := prepareTestFiles()
	if err != nil {
		t.Fatal("error preparing CSV testing files")
	}
	defer deleteTestingFiles()

	// Launch testing server
	go func() {
		e.Start(":50032")
	}()

	waitForTestServer(t, ":50032")

	testCases := []CmdTestCase{
		{
			name:           "login successful",
			cmd:            LoginCmd(),
			args:           []string{"--server", "http://127.0.0.1:50032", "--username", "admin", "--password", "test"},
			errorMessage:   "",
			successMessage: "Login succeeded\n",
		},
		{
			name:           "new group test",
			cmd:            NewGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:50032", "--group", "test", "--description", "test", "--members", "kim,saul"},
			errorMessage:   "",
			successMessage: "Group created\n",
		},
		{
			name:           "file not found",
			cmd:            CsvCreateUsersCmd(),
			args:           []string{"--server", "http://127.0.0.1:50032", "--file", "/tmp/file1"},
			errorMessage:   "can't open CSV file",
			successMessage: "",
		},
		{
			name:           "create users should be succesful",
			cmd:            CsvCreateUsersCmd(),
			args:           []string{"--server", "http://127.0.0.1:50032", "--file", "/tmp/file1.csv"},
			errorMessage:   "",
			successMessage: "gumball: successfully created\nanais: successfully created\nCreate from CSV finished!\n",
		},
		{
			name:           "group test detail",
			cmd:            ListGroupCmd(),
			args:           []string{"--server", "http://127.0.0.1:50032", "--gid", "1", "--json"},
			errorMessage:   "",
			successMessage: `{"gid":1,"name":"test","description":"test","members":[{"uid":3,"username":"saul","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":4,"username":"kim","name":"","firstname":"","lastname":"","email":"","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":false},{"uid":6,"username":"gumball","name":"Gumball Watterson","firstname":"Gumball","lastname":"Watterson","email":"gumbal@example.org","ssh_public_key":"","jpeg_photo":"","manager":true,"readonly":false,"locked":false},{"uid":7,"username":"anais","name":"Anais Watterson","firstname":"Anais","lastname":"Watterson","email":"anais@example.org","ssh_public_key":"","jpeg_photo":"","manager":false,"readonly":false,"locked":true}],"guac_config_protocol":"","guac_config_parameters":""}` + "\n",
		},
		{
			name:           "repeat file, users should be skipped",
			cmd:            CsvCreateUsersCmd(),
			args:           []string{"--server", "http://127.0.0.1:50032", "--file", "/tmp/file1.csv"},
			errorMessage:   "",
			successMessage: "gumball: skipped, user already exists\nanais: skipped, user already exists\nCreate from CSV finished!\n",
		},
		{
			name:           "file without users",
			cmd:            CsvCreateUsersCmd(),
			args:           []string{"--server", "http://127.0.0.1:50032", "--file", "/tmp/file2.csv"},
			errorMessage:   "no users where found in CSV file",
			successMessage: "",
		},
		{
			name:           "file with wrong header",
			cmd:            CsvCreateUsersCmd(),
			args:           []string{"--server", "http://127.0.0.1:50032", "--file", "/tmp/file3.csv"},
			errorMessage:   "wrong header",
			successMessage: "",
		},
		{
			name:           "file with users that have several errors",
			cmd:            CsvCreateUsersCmd(),
			args:           []string{"--server", "http://127.0.0.1:50032", "--file", "/tmp/file4.csv"},
			errorMessage:   "",
			successMessage: "test1: skipped, cannot be both manager and readonly at the same time\n\ntest1: skipped, email should have a valid format\n\ntest1: skipped, could not convert JPEG photo to Base64 open /tmp/nonexistent: no such file or directory\n\nCreate from CSV finished!\n",
		},
	}

	for _, tc := range testCases {
		runTests(t, tc)
	}

}
