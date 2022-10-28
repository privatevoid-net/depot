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

func CsvCreateGroupsCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "create",
		Short: "Create groups from a CSV file",
		PreRun: func(cmd *cobra.Command, _ []string) {
			viper.BindPFlags(cmd.Flags())
		},
		RunE: func(cmd *cobra.Command, _ []string) error {
			// json output?
			jsonOutput := viper.GetBool("json")
			messages := []string{}

			// Read and open file
			groups, err := readGroupsFromCSV(jsonOutput, "name,description,members,guac_config_protocol,guac_config_parameters")
			if err != nil {
				return err
			}

			if len(groups) == 0 {
				return fmt.Errorf("no groups where found in CSV file")
			}

			// Glim server URL
			url := viper.GetString("server")
			endpoint := fmt.Sprintf("%s/v1/groups", url)

			// Get credentials
			token, err := GetCredentials(url)
			if err != nil {
				printError(err.Error(), jsonOutput)
				os.Exit(1)
			}

			// Rest API authentication
			client := RestClient(token.AccessToken)

			for _, group := range groups {
				name := *group.Name
				resp, err := client.R().
					SetHeader("Content-Type", "application/json").
					SetBody(models.JSONGroupBody{
						Name:                      *group.Name,
						Description:               *group.Description,
						Members:                   *group.GroupMembers,
						GuacamoleConfigProtocol:   *group.GuacamoleConfigProtocol,
						GuacamoleConfigParameters: *group.GuacamoleConfigParameters,
					}).
					SetError(&types.APIError{}).
					Post(endpoint)

				if err != nil {
					return fmt.Errorf("can't connect with Glim: %v", err)
				}

				if resp.IsError() {
					messages = append(messages, fmt.Sprintf("%s: skipped, %v", name, resp.Error().(*types.APIError).Message))
					continue
				}
				messages = append(messages, fmt.Sprintf("%s: successfully created", name))
			}

			printCSVMessages(cmd, messages, jsonOutput)
			if !jsonOutput {
				printCmdMessage(cmd, "Create from CSV finished!", jsonOutput)
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
