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

package api

import (
	"context"
	"sync"
	"time"

	"github.com/labstack/echo/v4/middleware"
	"github.com/labstack/gommon/log"

	"github.com/doncicuto/glim/server/api/handlers"
	"github.com/doncicuto/glim/types"
)

// Server - TODO command
func Server(wg *sync.WaitGroup, shutdownChannel chan bool, settings types.APISettings) {
	defer wg.Done()

	// Get instance of Echo
	e := handlers.EchoServer(settings)

	// Set logger level
	e.Logger.SetLevel(log.ERROR)
	e.Logger.SetHeader("${time_rfc3339} [Glim] ⇨")
	e.Use(middleware.LoggerWithConfig(middleware.LoggerConfig{
		Format: "${time_rfc3339} [REST] ⇨ ${status} ${method} ${uri} ${remote_ip} ${error}\n",
	}))
	e.Logger.Printf("starting REST API in address %s...", settings.Address)

	go func() {
		if err := e.StartTLS(settings.Address, settings.TLSCert, settings.TLSKey); err != nil {
			e.Logger.Printf("shutting down REST API server...")
		}
	}()

	// Wait for shutdown signals and gracefully shutdown echo server (10 seconds timeout)
	// Reference: https://echo.labstack.com/cookbook/graceful-shutdown
	<-shutdownChannel
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := e.Shutdown(ctx); err != nil {
		e.Logger.Fatal(err)
	}

}
