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

// userCmd represents the user command
var userCmd = &cobra.Command{
	Use:   "user",
	Short: "Manage Glim user accounts",
	PreRun: func(cmd *cobra.Command, _ []string) {
		viper.BindPFlags(cmd.Flags())
	},
	RunE: func(cmd *cobra.Command, _ []string) error {
		return GetUserInfo(cmd)
	},
}

func init() {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Printf("Could not get your home directory: %v\n", err)
	}
	defaultRootPEMFilePath := filepath.Join(homeDir, ".glim", "ca.pem")

	rootCmd.AddCommand(userCmd)
	userCmd.PersistentFlags().String("tlscacert", defaultRootPEMFilePath, "trust certs signed only by this CA")
	userCmd.PersistentFlags().String("server", "https://127.0.0.1:1323", "glim REST API server address")
	userCmd.PersistentFlags().Bool("json", false, "encodes Glim output as json string")
	userCmd.AddCommand(ListUserCmd())
	userCmd.AddCommand(NewUserCmd())
	userCmd.AddCommand(UpdateUserCmd())
	userCmd.AddCommand(DeleteUserCmd())
	userCmd.AddCommand(UserPasswdCmd())
	userCmd.Flags().UintP("uid", "i", 0, "user account id")
	userCmd.Flags().StringP("username", "u", "", "username")
}
