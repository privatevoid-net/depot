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
	"net/mail"
	"strings"

	"github.com/doncicuto/glim/models"
	"github.com/golang-jwt/jwt"
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

// AddMembersOf - TODO comment
func (h *Handler) AddMembersOf(u *models.User, memberOf []string) error {
	var err error
	// Update group
	for _, member := range memberOf {
		member = strings.TrimSpace(member)
		// Find group
		g := new(models.Group)
		err = h.DB.Model(&models.Group{}).Where("name = ?", member).Take(&g).Error
		if err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return &echo.HTTPError{Code: http.StatusNotFound, Message: fmt.Sprintf("group %s not found", member)}
			}
			return err
		}

		// Append association
		err = h.DB.Model(&u).Association("MemberOf").Append(g)
		if err != nil {
			return err
		}
	}
	return nil
}

// SaveUser - TODO comment
// @Summary      Create a new user
// @Description  Create a new user in our database
// @Tags         users
// @Accept       json
// @Produce      json
// @Param        user  body models.JSONUserBody  true  "User account body. Username is required. The members property expect a comma-separated list of group names e.g 'admin,devel' that you want the user be member of. Password property is optional, if set it will be the password for that user, if no password is sent the user account will be locked (user can not log in). Manager property if true will assign the Manager role. Readonly property if true will set this user for read-only usage (queries). Locked property if true will disable log in for that user. Remove and replace properties are not currently used."
// @Success      200  {object}  models.UserInfo
// @Failure			 400  {object} types.ErrorResponse
// @Failure			 401  {object} types.ErrorResponse
// @Failure 	   404  {object} types.ErrorResponse
// @Failure 	   406  {object} types.ErrorResponse
// @Failure 	   500  {object} types.ErrorResponse
// @Router       /users [post]
// @Security 		 Bearer
func (h *Handler) SaveUser(c echo.Context) error {
	u := new(models.User)

	// Get username that is updating this user
	createdBy := new(models.User)
	if c.Get("user") == nil {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "wrong token or missing info in token claims"}
	}
	tokenUser := c.Get("user").(*jwt.Token)
	claims := tokenUser.Claims.(jwt.MapClaims)
	tokenUID, ok := claims["uid"].(float64)
	if !ok {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "wrong token or missing info in token claims"}
	}
	if err := h.DB.Model(&models.User{}).Where("id = ?", uint(tokenUID)).First(&createdBy).Error; err != nil {
		return &echo.HTTPError{Code: http.StatusForbidden, Message: "wrong user attempting to create user"}
	}

	body := models.JSONUserBody{}
	// Bind
	if err := c.Bind(&body); err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}

	// Validate
	if body.Username == "" {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "required username"}
	}
	u.Username = &body.Username

	name := strings.Join([]string{body.GivenName, body.Surname}, " ")
	u.Name = &name
	u.GivenName = &body.GivenName
	u.Surname = &body.Surname

	if body.Email != "" {
		if _, err := mail.ParseAddress(body.Email); err != nil {
			return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "invalid email"}
		}
	}
	u.Email = &body.Email

	u.SSHPublicKey = &body.SSHPublicKey

	if body.JPEGPhoto != "" {
		u.JPEGPhoto = &body.JPEGPhoto
	}

	if body.Manager != nil {
		u.Manager = body.Manager
	}

	if body.Readonly != nil {
		u.Readonly = body.Readonly
	}

	if body.Locked != nil {
		u.Locked = body.Locked
	}

	userUUID := uuid.New().String()
	u.UUID = &userUUID

	u.CreatedBy = createdBy.Username
	u.UpdatedBy = createdBy.Username

	// Check if user already exists
	err := h.DB.Model(&models.User{}).Where("username = ?", body.Username).First(&u).Error
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return &echo.HTTPError{Code: http.StatusBadRequest, Message: "user already exists"}
	}

	// Hash password
	hashedPassword, err := models.Hash(body.Password)
	if err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}
	password := string(hashedPassword)
	u.Password = &password

	// Add new user
	err = h.DB.Model(models.User{}).Create(&u).Error
	if err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}

	// Get new user
	err = h.DB.Where("username = ?", body.Username).First(&u).Error
	if err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}

	// Add group members
	if body.MemberOf != "" {
		members := strings.Split(body.MemberOf, ",")
		err = h.AddMembersOf(u, members)
		if err != nil {
			return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
		}
	}

	showMemberOf := true
	i := models.GetUserInfo(*u, showMemberOf, h.Guacamole)
	return c.JSON(http.StatusOK, i)
}
