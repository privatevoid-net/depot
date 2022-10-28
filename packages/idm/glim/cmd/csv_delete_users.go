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

	"github.com/doncicuto/glim/models"
	"github.com/doncicuto/glim/types"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func CsvDeleteUsersCmd() *cobra.Command {

	cmd := &cobra.Command{
		Use:   "rm",
		Short: "Remove users included in a CSV file",
		PreRun: func(cmd *cobra.Command, _ []string) {
			viper.BindPFlags(cmd.Flags())
		},
		RunE: func(cmd *cobra.Command, _ []string) error {
			// json output?
			jsonOutput := viper.GetBool("json")

			// Read and open file
			users, err := readUsersFromCSV(jsonOutput, "uid, username")
			if err != nil {
				return err
			}

			messages := []string{}

			if len(users) == 0 {
				return fmt.Errorf("no users where found in CSV file")
			}

			// Glim server URL
			url := viper.GetString("server")

			// Get credentials
			token, err := GetCredentials(url)
			if err != nil {
				printError(err.Error(), jsonOutput)
				os.Exit(1)
			}

			// Rest API authentication
			client := RestClient(token.AccessToken)

			for _, user := range users {
				username := *user.Username
				uid := user.ID

				if username == "" && uid <= 0 {
					messages = append(messages, fmt.Sprintf("UID %d: skipped, invalid username and uid\n", uid))
					continue
				}

				if username != "" {
					endpoint := fmt.Sprintf("%s/v1/users/%s/uid", url, username)
					resp, err := client.R().
						SetHeader("Content-Type", "application/json").
						SetResult(models.User{}).
						SetError(&types.APIError{}).
						Get(endpoint)

					if err != nil {
						return fmt.Errorf("can't connect with Glim: %v", err)
					}

					if resp.IsError() {
						messages = append(messages, fmt.Sprintf("%s: skipped, %v\n", username, resp.Error().(*types.APIError).Message))
						continue
					}

					result := resp.Result().(*models.User)

					if result.ID != uid && uid != 0 {
						messages = append(messages, fmt.Sprintf("%s: skipped, username and uid found in CSV doesn't match\n", username))
						continue
					}
					uid = result.ID
				}

				// Delete using API
				endpoint := fmt.Sprintf("%s/v1/users/%d", url, uid)
				resp, err := client.R().
					SetHeader("Content-Type", "application/json").
					SetError(&types.APIError{}).
					Delete(endpoint)

				if err != nil {
					return fmt.Errorf("can't connect with Glim: %v", err)
				}

				if resp.IsError() {
					if username != "" {
						error := fmt.Sprintf("%s: skipped, %v", username, resp.Error().(*types.APIError).Message)
						messages = append(messages, error)
					} else {
						error := fmt.Sprintf("UID %d: skipped, %v", uid, resp.Error().(*types.APIError).Message)
						messages = append(messages, error)
					}
					continue
				}

				message := fmt.Sprintf("%s: successfully removed\n", username)
				messages = append(messages, message)
			}

			printCSVMessages(cmd, messages, jsonOutput)
			if !jsonOutput {
				printCmdMessage(cmd, "Remove from CSV finished!", jsonOutput)
			}
			return nil
		},
	}

	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Printf("Could not get your home directory: %v\n", err)
	}
	defaultRootPEMFilePath := filepath.Join(homeDir, ".glim", "ca.pem")

	cmd.PersistentFlags().String("tlscacert", defaultRootPEMFilePath, "trust certs signed only by this CA")
	cmd.PersistentFlags().String("server", "https://127.0.0.1:1323", "glim REST API server address")
	cmd.PersistentFlags().Bool("json", false, "encodes Glim output as json string")
	cmd.Flags().StringP("file", "f", "", "path to CSV file, use README to know more about the format")
	cmd.MarkFlagRequired("file")

	return cmd
}
