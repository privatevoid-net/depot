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
	"html"
	"net/http"
	"net/mail"
	"strconv"
	"strings"
	"time"

	"github.com/doncicuto/glim/models"
	"github.com/golang-jwt/jwt"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

// RemoveMembersOf - TODO comment
func (h *Handler) RemoveMembersOf(u *models.User, memberOf []string) error {
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

		// Delete association
		err = h.DB.Model(&u).Association("MemberOf").Delete(g)
		if err != nil {
			return err
		}
	}
	return nil
}

// UpdateUser - TODO comment
// @Summary      Update user account information
// @Description  Update user account information
// @Tags         users
// @Accept       json
// @Produce      json
// @Param        id   path      int  true  "User Account ID"
// @Param        user  body models.JSONUserBody  true  "User account body. Username is required. The members property expect a comma-separated list of group names e.g 'admin,devel'. Password property is optional, if set it will be the password for that user, if no password is sent the user account will be locked (user can not log in). Manager property if true will assign the Manager role. Readonly property if true will set this user for read-only usage (queries). Locked property if true will disable log in for that user. Remove property if true will remove group membership from those specified in the members property. Remove property if true will replace group membership from those specified in the members property. Name property is not used"
// @Success      200  {object}  models.UserInfo
// @Failure			 400  {object} types.ErrorResponse
// @Failure			 401  {object} types.ErrorResponse
// @Failure 	   404  {object} types.ErrorResponse
// @Failure 	   500  {object} types.ErrorResponse
// @Router       /users/{id} [put]
// @Security 		 Bearer
func (h *Handler) UpdateUser(c echo.Context) error {
	var updatedUser = make(map[string]interface{})

	u := new(models.User)

	// Get username that is updating this user
	modifiedBy := new(models.User)
	if c.Get("user") == nil {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "wrong token or missing info in token claims"}
	}
	tokenUser := c.Get("user").(*jwt.Token)
	claims := tokenUser.Claims.(jwt.MapClaims)
	tokenUID, ok := claims["uid"].(float64)
	if !ok {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "wrong token or missing info in token claims"}
	}

	manager, ok := claims["manager"].(bool)
	if !ok {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "wrong token or missing info in token claims"}
	}

	if err := h.DB.Model(&models.User{}).Where("id = ?", uint(tokenUID)).First(&modifiedBy).Error; err != nil {
		return &echo.HTTPError{Code: http.StatusForbidden, Message: "wrong user attempting to update account"}
	}

	// User id cannot be empty
	if c.Param("uid") == "" {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "required user uid"}
	}

	// Get idparam
	uid, err := strconv.ParseUint(c.Param("uid"), 10, 32)
	if err != nil {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "uid param should be a valid integer"}
	}

	// Bind
	body := new(models.JSONUserBody)
	if err := c.Bind(body); err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}

	// Find user
	err = h.DB.Where("id = ?", uid).First(&u).Error
	if err != nil {
		// Does user exist?
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return &echo.HTTPError{Code: http.StatusNotFound, Message: "user not found"}
		}
		return err
	}

	// Validate other fields
	if body.Username != "" {
		err := h.DB.Model(&models.User{}).Where("username = ? AND id <> ?", body.Username, uid).First(&models.User{}).Error
		if err != nil {
			// Does username exist?
			if errors.Is(err, gorm.ErrRecordNotFound) {
				if !manager {
					return &echo.HTTPError{Code: http.StatusForbidden, Message: "only managers can update the username"}
				}
				updatedUser["username"] = html.EscapeString(strings.TrimSpace(body.Username))
			}
		} else {
			return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "username cannot be duplicated"}
		}
	}

	if body.GivenName != "" {
		updatedUser["given_name"] = html.EscapeString(strings.TrimSpace(body.GivenName))
		if body.Surname != "" {
			updatedUser["name"] = fmt.Sprintf("%s %s", updatedUser["given_name"], html.EscapeString(strings.TrimSpace(body.Surname)))
		} else {
			updatedUser["name"] = fmt.Sprintf("%s %s", updatedUser["given_name"], *u.Surname)
		}
	}

	if body.Surname != "" {
		updatedUser["surname"] = html.EscapeString(strings.TrimSpace(body.Surname))
		if body.GivenName != "" {
			updatedUser["name"] = fmt.Sprintf("%s %s", html.EscapeString(strings.TrimSpace(body.GivenName)), updatedUser["surname"])
		} else {
			updatedUser["name"] = fmt.Sprintf("%s %s", *u.GivenName, updatedUser["surname"])
		}
	}

	if body.Email != "" {
		if _, err := mail.ParseAddress(body.Email); err != nil {
			return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "invalid email"}
		}
		updatedUser["email"] = body.Email
	}

	if body.SSHPublicKey != "" {
		updatedUser["ssh_public_key"] = body.SSHPublicKey
	}

	if body.JPEGPhoto != "" {
		updatedUser["jpeg_photo"] = body.JPEGPhoto
	}

	if body.Manager != nil {
		if !manager {
			return &echo.HTTPError{Code: http.StatusForbidden, Message: "only managers can update manager status"}
		}
		updatedUser["manager"] = *body.Manager
	}

	if body.Readonly != nil {
		if !manager {
			return &echo.HTTPError{Code: http.StatusForbidden, Message: "only managers can update readonly status"}
		}
		updatedUser["readonly"] = *body.Readonly
	}

	if body.Locked != nil {
		if !manager {
			return &echo.HTTPError{Code: http.StatusForbidden, Message: "only managers can update locked status"}
		}
		updatedUser["locked"] = *body.Locked
	}

	if body.ReplaceMembersOf && body.RemoveMembersOf {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "replace and replace are mutually exclusive"}
	}

	// Update date
	updatedUser["updated_at"] = time.Now()
	updatedUser["updated_by"] = *modifiedBy.Username

	// Update user
	err = h.DB.Model(&models.User{}).Where("id = ?", uid).Updates(updatedUser).Error
	if err != nil {
		// Does user exist?
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return &echo.HTTPError{Code: http.StatusNotFound, Message: "user not found"}
		}
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}

	// Get updated user
	err = h.DB.Where("id = ?", uid).First(&u).Error
	if err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}

	// Update group members
	if body.MemberOf != "" {
		if !manager {
			return &echo.HTTPError{Code: http.StatusForbidden, Message: "only managers can update group memberships"}
		}
		members := strings.Split(body.MemberOf, ",")

		if body.ReplaceMembersOf {
			// We are going to replace all user memberof, so let's clear the associations first
			err = h.DB.Model(&u).Association("MemberOf").Clear()
			if err != nil {
				return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
			}
		}

		if body.RemoveMembersOf {
			err = h.RemoveMembersOf(u, members)
			if err != nil {
				return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
			}
		} else {
			err = h.AddMembersOf(u, members)
			if err != nil {
				return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
			}
		}
	}

	// Get updated user
	err = h.DB.Where("id = ?", uid).First(&u).Error
	if err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}

	// Return user
	showMemberOf := true
	return c.JSON(http.StatusOK, models.GetUserInfo(*u, showMemberOf, h.Guacamole))
}
