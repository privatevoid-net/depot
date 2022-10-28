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
	"html"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/doncicuto/glim/models"
	"github.com/golang-jwt/jwt"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

// UpdateGroup - TODO comment
// @Summary      Update group
// @Description  Update group
// @Tags         groups
// @Accept       json
// @Produce      json
// @Param        id   path      int  true  "Group ID"
// @Param        group body models.JSONGroupBody  true  "Group body. All properties are optional. The members property expect a comma-separated list of usernames e.g 'bob,sally'. The replace property if true will replace all members by those selected by the members property, if replace is false the member will be added to current members."
// @Success      200  {object}  models.UserInfo
// @Failure			 400  {object} types.ErrorResponse
// @Failure			 401  {object} types.ErrorResponse
// @Failure 	   404  {object} types.ErrorResponse
// @Failure 	   406  {object} types.ErrorResponse
// @Failure 	   500  {object} types.ErrorResponse
// @Router       /groups/{id} [put]
// @Security 		 Bearer
func (h *Handler) UpdateGroup(c echo.Context) error {
	var modifiedBy = make(map[string]interface{})
	g := new(models.Group)
	u := new(models.User)
	body := models.JSONGroupBody{}

	// Get username that is updating this group
	if c.Get("user") == nil {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "wrong token or missing info in token claims"}
	}
	user := c.Get("user").(*jwt.Token)

	claims := user.Claims.(jwt.MapClaims)
	uid, ok := claims["uid"].(float64)
	if !ok {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "wrong token or missing info in token claims"}
	}
	if err := h.DB.Model(&models.User{}).Where("id = ?", uint(uid)).First(&u).Error; err != nil {
		return &echo.HTTPError{Code: http.StatusForbidden, Message: "wrong user attempting to update group"}
	}

	// Group cannot be empty
	if c.Param("gid") == "" {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "required group gid"}

	}

	// Get gid
	gid, err := strconv.ParseUint(c.Param("gid"), 10, 32)
	if err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: "could not convert gid into uint"}
	}
	// Get request body
	if err := c.Bind(&body); err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}

	// Find group
	if err := h.DB.Model(&models.Group{}).Where("id = ?", gid).First(&g).Error; err != nil {
		// Does group exist?
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return &echo.HTTPError{Code: http.StatusNotFound, Message: "group not found"}
		}
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}

	// Validate other fields
	if body.Name != "" {
		err := h.DB.Model(&models.Group{}).Where("name = ? AND id <> ?", body.Name, gid).First(&models.Group{}).Error
		if err != nil {
			// Does group name exist?
			if errors.Is(err, gorm.ErrRecordNotFound) {
				modifiedBy["name"] = html.EscapeString(strings.TrimSpace(body.Name))
			}
		} else {
			return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "group name cannot be duplicated"}
		}
	}

	if body.Description != "" {
		modifiedBy["description"] = html.EscapeString(strings.TrimSpace(body.Description))
	}

	// Validate Apache Guacamole protocol and parameters
	if !h.Guacamole && (body.GuacamoleConfigParameters != "" || body.GuacamoleConfigProtocol != "") {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "Apache Guacamole support not set in server"}
	}

	if body.GuacamoleConfigParameters != "" && *g.GuacamoleConfigProtocol == "" {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "Apache Guacamole config protocol is required"}
	}

	if body.GuacamoleConfigProtocol != "" {
		modifiedBy["guacamole_config_protocol"] = html.EscapeString(strings.TrimSpace(body.GuacamoleConfigProtocol))
	}

	if body.GuacamoleConfigParameters != "" {
		modifiedBy["guacamole_config_parameters"] = html.EscapeString(strings.TrimSpace(body.GuacamoleConfigParameters))
	}

	// New update date
	modifiedBy["updated_at"] = time.Now()
	modifiedBy["updated_by"] = *u.Username

	// Update group
	if err := h.DB.Model(&models.Group{}).Where("id = ?", gid).Updates(modifiedBy).Error; err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}

	// Get updated group
	if err := h.DB.Model(&models.Group{}).Where("id = ?", gid).First(&g).Error; err != nil {
		// Does group exist?
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return &echo.HTTPError{Code: http.StatusNotFound, Message: "group not found"}
		}
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}

	// Update group members
	if body.Members != "" {
		members := strings.Split(body.Members, ",")

		if body.ReplaceMembers {
			// We are going to replace all group members, so let's clear the associations first
			err := h.DB.Model(&g).Association("Members").Clear()
			if err != nil {
				return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
			}
		}

		err := h.AddMembers(g, members)
		if err != nil {
			return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
		}
	}

	// Get updated group
	g = new(models.Group)
	if err := h.DB.Preload("Members").Model(&models.Group{}).Where("id = ?", gid).First(&g).Error; err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}

	// Return group
	showMembers := true
	return c.JSON(http.StatusOK, models.GetGroupInfo(g, showMembers, h.Guacamole))
}
