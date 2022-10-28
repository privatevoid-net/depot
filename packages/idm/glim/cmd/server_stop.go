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
	"io/ioutil"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"syscall"
	"time"

	"github.com/spf13/cobra"
)

// serverCmd represents the server command
var serverStopCmd = &cobra.Command{
	Use:   "stop",
	Short: "Stop a Glim server. Windows systems are not supported.",
	Run: func(_ *cobra.Command, _ []string) {
		// SIGTERM cannot be used with Go in Windows Ref: https://golang.org/pkg/os/#Signal
		/* if runtime.GOOS == "windows" {
			fmt.Printf("%s [Glim] ⇨ stop command is not supported for Windows platform as it doesn't support the SIGTERM signal. You should terminate Glim process by hand (Ctrl-C). \n", time.Now().Format(time.RFC3339))
			os.Exit(1)
		} */

		// Try to read glim.pid file in order to get server's PID
		pidFile := filepath.FromSlash(fmt.Sprintf("%s/glim.pid", os.TempDir()))

		data, err := ioutil.ReadFile(pidFile)
		if err != nil {
			fmt.Printf("%s [Glim] ⇨ could not find process file: %s. You should terminate Glim process by hand (Ctrl-C?). \n", pidFile, time.Now().Format(time.RFC3339))
			os.Exit(1)
		}

		pid, err := strconv.Atoi(string(data))
		if err != nil {
			fmt.Printf("%s [Glim] ⇨ could not read PID from %s. You should terminate Glim process by hand (Ctrl-C?). \n", pidFile, time.Now().Format(time.RFC3339))
			os.Exit(1)
		}

		p, err := os.FindProcess(pid)
		if err != nil {
			fmt.Printf("%s [Glim] ⇨ could not find PID in process list. You should terminate Glim process by hand (Ctrl-C?). \n", time.Now().Format(time.RFC3339))
			os.Exit(1)
		}

		if runtime.GOOS == "windows" {
			err = p.Signal(syscall.SIGINT)
			if err != nil {
				fmt.Printf("%s [Glim] ⇨ could not send SIGTERM signal to Glim. You should terminate Glim process by hand (Ctrl-C?). \n", time.Now().Format(time.RFC3339))
				os.Exit(1)
			}
		} else {
			err = p.Signal(syscall.SIGTERM)
			if err != nil {
				fmt.Printf("%s [Glim] ⇨ could not send SIGTERM signal to Glim. You should terminate Glim process by hand (Ctrl-C?). \n", time.Now().Format(time.RFC3339))
				os.Exit(1)
			}
		}
	},
}
