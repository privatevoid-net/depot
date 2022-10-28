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
	"fmt"
	"net/http"
	"strings"

	"github.com/doncicuto/glim/models"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

//RemoveGroupMembers - TODO comment
// @Summary      Remove members from a group
// @Description  Remove members from a group
// @Tags         groups
// @Accept       json
// @Produce      json
// @Param        id   path      int  true  "Group ID"
// @Param        members body models.GroupMembers  true  "Group members body. The members property expect a comma-separated list of usernames e.g 'bob,sally' to be removed from the group"
// @Success      204
// @Failure			 400  {object} types.ErrorResponse
// @Failure			 401  {object} types.ErrorResponse
// @Failure 	   404  {object} types.ErrorResponse
// @Failure 	   406  {object} types.ErrorResponse
// @Failure 	   500  {object} types.ErrorResponse
// @Router       /groups/{id}/members [delete]
// @Security 		 Bearer
func (h *Handler) RemoveGroupMembers(c echo.Context) error {
	// Get gid
	gid := c.Param("gid")

	// Group cannot be empty
	if gid == "" {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "required group gid"}
	}

	// Bind
	m := new(models.GroupMembers)
	if err := c.Bind(m); err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}
	members := strings.Split(m.Members, ",")

	// Find group
	g := new(models.Group)
	err := h.DB.Model(&models.Group{}).Where("id = ?", gid).First(&g).Error
	if err != nil {
		// Does group exist?
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return &echo.HTTPError{Code: http.StatusNotFound, Message: "group not found"}
		}
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}

	// Update group
	for _, member := range members {

		// Find user
		u := new(models.User)
		err = h.DB.Model(&models.User{}).Where("username = ?", member).Take(&u).Error
		if err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				continue
			}
			return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
		}

		// Delete association
		err = h.DB.Model(&g).Association("Members").Delete(u)
		if err != nil {
			return &echo.HTTPError{Code: http.StatusInternalServerError, Message: fmt.Sprintf("could not remove member from group. Error: %v", err)}
		}
	}

	// Return 204
	return c.NoContent(http.StatusNoContent)
}
