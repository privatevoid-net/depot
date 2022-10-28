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

	"github.com/Songmu/prompter"
	"github.com/doncicuto/glim/types"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

// DeleteUserCmd - TODO comment
func DeleteUserCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "rm",
		Short: "Remove a Glim user account",
		PreRun: func(cmd *cobra.Command, _ []string) {
			viper.BindPFlags(cmd.Flags())
		},
		RunE: func(cmd *cobra.Command, _ []string) error {
			force := viper.GetBool("force")

			if !force {
				confirm := prompter.YesNo("Do you really want to delete this user?", false)
				if !confirm {
					return fmt.Errorf("ok, user wasn't deleted")
				}
			}

			url := viper.GetString("server")
			uid := viper.GetUint("uid")
			username := viper.GetString("username")

			// Get credentials
			token, err := GetCredentials(url)
			if err != nil {
				return err
			}

			// JSON output?
			jsonOutput := viper.GetBool("json")

			client := RestClient(token.AccessToken)
			if uid == 0 && username != "" {
				uid, err = getUIDFromUsername(client, username, url)
				if err != nil {
					return err
				}
			}

			// Rest API authentication
			endpoint := fmt.Sprintf("%s/v1/users/%d", url, uid)
			resp, err := client.R().
				SetHeader("Content-Type", "application/json").
				SetError(&types.APIError{}).
				Delete(endpoint)

			if err != nil {
				return fmt.Errorf("can't connect with Glim: %v", err)
			}

			if resp.IsError() {
				return fmt.Errorf("%v", resp.Error().(*types.APIError).Message)
			}

			printCmdMessage(cmd, "User account deleted", jsonOutput)
			return nil
		},
	}

	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Printf("Could not get your home directory: %v\n", err)
	}
	defaultRootPEMFilePath := filepath.Join(homeDir, ".glim", "ca.pem")

	cmd.Flags().UintP("uid", "i", 0, "user account id")
	cmd.Flags().StringP("username", "u", "", "username")
	cmd.Flags().BoolP("force", "f", false, "force delete and don't ask for confirmation")
	cmd.PersistentFlags().String("tlscacert", defaultRootPEMFilePath, "trust certs signed only by this CA")
	cmd.PersistentFlags().String("server", "https://127.0.0.1:1323", "glim REST API server address")
	cmd.PersistentFlags().Bool("json", false, "encodes Glim output as json string")

	return cmd
}
