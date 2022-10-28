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

func UpdateGroupCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "update",
		Short: "Update a Glim group",
		PreRun: func(cmd *cobra.Command, _ []string) {
			viper.BindPFlags(cmd.Flags())
		},
		RunE: func(cmd *cobra.Command, _ []string) error {
			// json output?
			jsonOutput := viper.GetBool("json")

			// Glim server URL
			url := viper.GetString("server")

			// Get credentials
			token, err := GetCredentials(url)
			if err != nil {
				return err
			}

			// Rest API authentication
			client := RestClient(token.AccessToken)

			gid := viper.GetUint("gid")
			group := viper.GetString("group")

			if gid == 0 && group == "" {
				return fmt.Errorf("you must specify either the group id or name")
			}

			if gid == 0 && group != "" {
				gid, err = getGIDFromGroupName(client, group, url)
				if err != nil {
					return err
				}
			}

			endpoint := fmt.Sprintf("%s/v1/groups/%d", url, gid)

			resp, err := client.R().
				SetHeader("Content-Type", "application/json").
				SetBody(models.JSONGroupBody{
					Name:                      viper.GetString("group"),
					Description:               viper.GetString("description"),
					Members:                   viper.GetString("members"),
					ReplaceMembers:            viper.GetBool("replace"),
					GuacamoleConfigProtocol:   viper.GetString("guacamole-protocol"),
					GuacamoleConfigParameters: viper.GetString("guacamole-parameters"),
				}).
				SetError(&types.APIError{}).
				Put(endpoint)

			if err != nil {
				return fmt.Errorf("can't connect with Glim: %v", err)
			}

			if resp.IsError() {
				return fmt.Errorf("%v", resp.Error().(*types.APIError).Message)
			}

			printCmdMessage(cmd, "Group updated", jsonOutput)
			return nil
		},
	}

	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Printf("Could not get your home directory: %v\n", err)
	}
	defaultRootPEMFilePath := filepath.Join(homeDir, ".glim", "ca.pem")

	cmd.Flags().UintP("gid", "i", 0, "group id")
	cmd.Flags().StringP("group", "g", "", "our group name")
	cmd.Flags().StringP("description", "d", "", "our group description")
	cmd.Flags().StringP("members", "m", "", "comma-separated list of usernames e.g: admin,tux")
	cmd.Flags().Bool("replace", false, "Replace group members with those specified with -m. Usernames are appended to members by default")
	cmd.PersistentFlags().String("tlscacert", defaultRootPEMFilePath, "trust certs signed only by this CA")
	cmd.PersistentFlags().String("server", "https://127.0.0.1:1323", "glim REST API server address")
	cmd.PersistentFlags().Bool("json", false, "encodes Glim output as json string")
	cmd.Flags().String("guacamole-protocol", "", "Apache Guacamole protocol e.g: vnc")
	cmd.Flags().String("guacamole-parameters", "", "Apache Guacamole config params using a comma-separated list e.g: hostname=localhost,port=5900,password=secret")
	return cmd
}
