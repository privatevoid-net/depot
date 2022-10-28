/*
Copyright © 2022 Miguel Ángel Álvarez Cabrerizo <mcabrerizo@sologitops.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package cmd

import (
	"bufio"
	"fmt"
	"os"

	"github.com/doncicuto/glim/models"
	"github.com/gocarina/gocsv"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func checkCSVHeader(header string) error {
	file := viper.GetString("file")
	csvFile, err := os.Open(file)
	if err != nil {
		return fmt.Errorf("can't open CSV file")
	}
	defer csvFile.Close()

	// Try to read first row and check if row is valid
	reader := bufio.NewReader(csvFile)
	line, _, err := reader.ReadLine()
	if err != nil {
		return err
	}

	if header != string(line) {
		return fmt.Errorf("wrong header")
	}
	return nil
}

func readUsersFromCSV(jsonOutput bool, header string) ([]*models.User, error) {
	// Read and open file
	file := viper.GetString("file")
	csvFile, err := os.Open(file)
	if err != nil {
		return nil, fmt.Errorf("can't open CSV file")
	}
	defer csvFile.Close()

	// Try to read first row and check if row is valid
	err = checkCSVHeader(header)
	if err != nil {
		return nil, err
	}

	// Try to unmarshal CSV file usin gocsv
	users := []*models.User{}
	if err := gocsv.UnmarshalFile(csvFile, &users); err != nil { // Load clients from file
		return nil, err
	}
	return users, nil
}

func readGroupsFromCSV(jsonOutput bool, header string) ([]*models.Group, error) {
	// Read and open file
	file := viper.GetString("file")
	csvFile, err := os.Open(file)
	if err != nil {
		return nil, fmt.Errorf("can't open CSV file")
	}
	defer csvFile.Close()

	// Try to read first row and check if row is valid
	err = checkCSVHeader(header)
	if err != nil {
		return nil, err
	}

	// Try to unmarshal CSV file usin gocsv
	groups := []*models.Group{}
	if err := gocsv.UnmarshalFile(csvFile, &groups); err != nil { // Load clients from file
		return nil, err
	}
	return groups, nil
}

// importCmd represents the import command
var csvCmd = &cobra.Command{
	Use:   "csv",
	Short: "Manage users and groups with CSV files",
	PreRun: func(cmd *cobra.Command, _ []string) {
		viper.BindPFlags(cmd.Flags())
	},
}

func init() {
	rootCmd.AddCommand(csvCmd)
	csvCmd.AddCommand(csvUsersCmd)
	csvCmd.AddCommand(csvGroupsCmd)
}
