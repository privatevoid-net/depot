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
	"errors"
	"net/http"
	"strconv"

	"github.com/doncicuto/glim/models"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

//DeleteGroup - TODO comment
// @Summary      Delete a group
// @Description  Delete a group
// @Tags         groups
// @Accept       json
// @Produce      json
// @Param        id   path      int  true  "Group ID"
// @Success      204
// @Failure			 400  {object} types.ErrorResponse
// @Failure			 401  {object} types.ErrorResponse
// @Failure 	   404  {object} types.ErrorResponse
// @Failure 	   406  {object} types.ErrorResponse
// @Failure 	   500  {object} types.ErrorResponse
// @Router       /groups/{id} [delete]
// @Security 		 Bearer
func (h *Handler) DeleteGroup(c echo.Context) error {
	var g models.Group
	// Group id cannot be empty
	if c.Param("gid") == "" {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "required group id"}
	}

	// Get idparam
	gid, err := strconv.ParseUint(c.Param("gid"), 10, 32)
	if err != nil {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "gid param should be a valid integer"}
	}

	err = h.DB.Model(&g).Where("id = ?", gid).Take(&g).Delete(&g).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return &echo.HTTPError{Code: http.StatusNotFound, Message: "group not found"}
		}
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}
	return c.NoContent(http.StatusNoContent)
}
