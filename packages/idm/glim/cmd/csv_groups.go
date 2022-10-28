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
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

// csvGroupsCmd represents the user command
var csvGroupsCmd = &cobra.Command{
	Use:   "groups",
	Short: "Manage groups with CSV files",
	PreRun: func(cmd *cobra.Command, _ []string) {
		viper.BindPFlags(cmd.Flags())
	},
}

func init() {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Printf("Could not get your home directory: %v\n", err)
	}
	defaultRootPEMFilePath := filepath.Join(homeDir, ".glim", "ca.pem")

	csvGroupsCmd.PersistentFlags().String("tlscacert", defaultRootPEMFilePath, "trust certs signed only by this CA")
	csvGroupsCmd.PersistentFlags().String("server", "https://127.0.0.1:1323", "glim REST API server address")
	csvGroupsCmd.PersistentFlags().Bool("json", false, "encodes Glim output as json string")
	csvGroupsCmd.AddCommand(CsvCreateGroupsCmd())
	csvGroupsCmd.AddCommand(CsvDeleteGroupsCmd())
}
