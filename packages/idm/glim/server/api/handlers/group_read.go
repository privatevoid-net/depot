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

// FindGroupByID - TODO comment
// @Summary      Find group by id
// @Description  Find group by id
// @Tags         groups
// @Accept       json
// @Produce      json
// @Param        id   path      int  true  "Group ID"
// @Success      200  {object}  models.GroupInfo
// @Failure			 400  {object} types.ErrorResponse
// @Failure			 401  {object} types.ErrorResponse
// @Failure 	   404  {object} types.ErrorResponse
// @Failure 	   500  {object} types.ErrorResponse
// @Router       /groups/{id} [get]
// @Security 		 Bearer
func (h *Handler) FindGroupByID(c echo.Context) error {
	var g models.Group
	var err error
	gid := c.Param("gid")

	err = h.DB.Preload("Members").Model(&models.Group{}).Where("id = ?", gid).Take(&g).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return &echo.HTTPError{Code: http.StatusNotFound, Message: "group not found"}
		}
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}

	showMembers := true
	i := models.GetGroupInfo(&g, showMembers, h.Guacamole)
	return c.JSON(http.StatusOK, i)
}

// FindGIDFromGroupName - TODO comment
// @Summary      Find user by group
// @Description  Find user by group
// @Tags         users
// @Accept       json
// @Produce      json
// @Param        group   path      string  true  "group"
// @Success      200  {object}  models.GroupID
// @Failure			 400  {object} types.ErrorResponse
// @Failure			 401  {object} types.ErrorResponse
// @Failure 	   404  {object} types.ErrorResponse
// @Failure 	   500  {object} types.ErrorResponse
// @Router       /groups/{group}/gid [get]
// @Security 		 Bearer
func (h *Handler) FindGIDFromGroupName(c echo.Context) error {
	var g models.Group
	var response models.GroupID
	var err error
	group := c.Param("group")

	err = h.DB.Model(&models.Group{}).Where("name = ?", group).Take(&g).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return &echo.HTTPError{Code: http.StatusNotFound, Message: "group not found"}
		}
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}

	response.ID = g.ID
	return c.JSON(http.StatusOK, response)
}

// FindAllGroups - TODO comment
// @Summary      Find all groups
// @Description  Find all groups
// @Tags         groups
// @Accept       json
// @Produce      json
// @Success      200  {object}  models.GroupInfo
// @Failure			 400  {object} types.ErrorResponse
// @Failure			 401  {object} types.ErrorResponse
// @Failure 	   500  {object} types.ErrorResponse
// @Router       /groups [get]
// @Security 		 Bearer
func (h *Handler) FindAllGroups(c echo.Context) error {
	page, _ := strconv.Atoi(c.QueryParam("page"))
	limit, _ := strconv.Atoi(c.QueryParam("limit"))

	// Defaults
	if page == 0 {
		page = 1
	}
	if limit == 0 {
		limit = 100
	}

	// Retrieve groups from database
	groups := []models.Group{}
	if err := h.DB.
		Preload("Members").
		Model(&models.Group{}).
		Offset((page - 1) * limit).
		Limit(limit).
		Find(&groups).Error; err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}

	if len(groups) == 0 {
		return c.JSON(http.StatusOK, []models.GroupInfo{})
	}

	var allGroups []models.GroupInfo
	showMembers := true
	for _, group := range groups {
		allGroups = append(allGroups, *models.GetGroupInfo(&group, showMembers, h.Guacamole))
	}

	return c.JSON(http.StatusOK, allGroups)
}
