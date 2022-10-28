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
	"net/http"

	"github.com/labstack/echo/v4"
)

// Healthz - Liveness probe
// @Summary      Check if Glim is running
// @Description  Get a boolean showing if Apache Guacamole support is enabled
// @Produce      json
// @Success      204
// @Failure 	   503  {object} types.ErrorResponse
// @Router       /healthz [get]
func (h *Handler) Healthz(c echo.Context) error {
	return c.NoContent(http.StatusNoContent)
}
