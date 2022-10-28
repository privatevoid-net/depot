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

package handlers

import (
	"fmt"
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
)

// Healthz - Readiness probe
// @Summary      Check if Glim is running
// @Description  Get a boolean showing if Apache Guacamole support is enabled
// @Produce      json
// @Success      204
// @Router       /readyz [get]
func (h *Handler) Readyz(c echo.Context) error {
	sqlDB, err := h.DB.DB()
	if err != nil {
		fmt.Println(err)
		return &echo.HTTPError{Code: http.StatusServiceUnavailable, Message: "cannot get generic database object"}
	}

	err = sqlDB.Ping()
	if err != nil {
		return &echo.HTTPError{Code: http.StatusServiceUnavailable, Message: "cannot ping database"}
	}

	err = h.KV.Set("test", "test", time.Second*1)
	if err != nil {
		return &echo.HTTPError{Code: http.StatusServiceUnavailable, Message: "cannot set value"}
	}

	value, found, err := h.KV.Get("test")
	if err != nil || !found || value != "test" {
		return &echo.HTTPError{Code: http.StatusServiceUnavailable, Message: "cannot get value"}
	}

	// Return OK
	return c.NoContent(http.StatusNoContent)
}
