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

// FindAllUsers - TODO comment
// @Summary      Find all users
// @Description  Find all users
// @Tags         users
// @Accept       json
// @Produce      json
// @Success      200  {object}  models.UserInfo
// @Failure 	   500  {object} types.ErrorResponse
// @Router       /users [get]
// @Security 		 Bearer
func (h *Handler) FindAllUsers(c echo.Context) error {
	page, _ := strconv.Atoi(c.QueryParam("page"))
	limit, _ := strconv.Atoi(c.QueryParam("limit"))

	// Defaults
	if page == 0 {
		page = 1
	}
	if limit == 0 {
		limit = 100
	}

	// Retrieve users from database
	users := []models.User{}
	if err := h.DB.
		Preload("MemberOf").
		Model(&models.User{}).
		Offset((page - 1) * limit).
		Limit(limit).
		Find(&users).Error; err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}

	if len(users) == 0 {
		return c.JSON(http.StatusOK, []models.UserInfo{})
	}

	var allUsers []models.UserInfo
	showMemberOf := true
	for _, user := range users {
		allUsers = append(allUsers, models.GetUserInfo(user, showMemberOf, h.Guacamole))
	}

	return c.JSON(http.StatusOK, allUsers)
}

// FindUserByID - TODO comment
// @Summary      Find user by id
// @Description  Find user by id
// @Tags         users
// @Accept       json
// @Produce      json
// @Param        id   path      int  true  "User Account ID"
// @Success      200  {object}  models.UserInfo
// @Failure			 400  {object} types.ErrorResponse
// @Failure			 401  {object} types.ErrorResponse
// @Failure 	   404  {object} types.ErrorResponse
// @Failure 	   500  {object} types.ErrorResponse
// @Router       /users/{id} [get]
// @Security 		 Bearer
func (h *Handler) FindUserByID(c echo.Context) error {
	var u models.User
	var err error
	uid := c.Param("uid")

	id, err := strconv.Atoi(uid)
	if err != nil {
		return &echo.HTTPError{Code: http.StatusBadRequest, Message: "uid param should be a valid integer"}
	}

	err = h.DB.Preload("MemberOf").Model(&models.User{}).Where("id = ?", id).Take(&u).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return &echo.HTTPError{Code: http.StatusNotFound, Message: "user not found"}
		}
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}

	showMemberOf := true
	i := models.GetUserInfo(u, showMemberOf, h.Guacamole)
	return c.JSON(http.StatusOK, i)
}

// FindUIDFromUsername - TODO comment
// @Summary      Find user by username
// @Description  Find user by username
// @Tags         users
// @Accept       json
// @Produce      json
// @Param        username   path      string  true  "username"
// @Success      200  {object}  models.UserID
// @Failure			 400  {object} types.ErrorResponse
// @Failure			 401  {object} types.ErrorResponse
// @Failure 	   404  {object} types.ErrorResponse
// @Failure 	   500  {object} types.ErrorResponse
// @Router       /users/{username}/uid [get]
// @Security 		 Bearer
func (h *Handler) FindUIDFromUsername(c echo.Context) error {
	var u models.User
	var response models.UserID
	var err error
	username := c.Param("username")

	err = h.DB.Model(&models.User{}).Where("username = ?", username).Take(&u).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return &echo.HTTPError{Code: http.StatusNotFound, Message: "user not found"}
		}
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}

	response.ID = u.ID
	return c.JSON(http.StatusOK, response)
}
