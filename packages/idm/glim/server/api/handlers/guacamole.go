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

	"github.com/doncicuto/glim/types"

	"github.com/labstack/echo/v4"
)

// GuacamoleSupport - Check if Apache Guacamole support is enabled
// @Summary      Check if Apache Guacamole support is enabled
// @Description  Get a boolean showing if Apache Guacamole support is enabled
// @Produce      json
// @Success      200  {object}  types.GuacamoleSupport
// @Failure			 400  {object} types.ErrorResponse
// @Failure 	   500  {object} types.ErrorResponse
// @Router       /guacamole [get]
func (h *Handler) GuacamoleSupport(c echo.Context) error {
	support := types.GuacamoleSupport{}
	support.Enabled = h.Guacamole
	return c.JSON(http.StatusOK, support)
}
