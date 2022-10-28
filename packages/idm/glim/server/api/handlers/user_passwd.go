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
	"time"

	"github.com/doncicuto/glim/models"
	"github.com/golang-jwt/jwt"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

//Passwd - TODO comment
// @Summary      Change user account password
// @Description  Change user account password
// @Tags         users
// @Accept       json
// @Produce      json
// @Param        id   path      int  true  "User Account ID"
// @Param        password body models.JSONPasswdBody  true  "Password body"
// @Success      204
// @Failure			 400  {object} types.ErrorResponse
// @Failure			 401  {object} types.ErrorResponse
// @Failure 	   403  {object} types.ErrorResponse
// @Failure 	   406  {object} types.ErrorResponse
// @Router       /users/{id}/passwd [post]
// @Security 		 Bearer
func (h *Handler) Passwd(c echo.Context) error {
	var dbUser models.User
	var newUser = make(map[string]interface{})

	// Get idparam
	uid := c.Param("uid")

	// User id cannot be empty
	if uid == "" {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "required user uid"}
	}

	// Bind body
	body := new(models.JSONPasswdBody)
	if err := c.Bind(body); err != nil {
		return err
	}

	// Get uid and manager status from JWT token
	if c.Get("user") == nil {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "wrong token or missing info in token claims"}
	}
	user := c.Get("user").(*jwt.Token)
	claims := user.Claims.(jwt.MapClaims)
	tokenUID, ok := claims["uid"].(float64)
	if !ok {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "wrong token or missing info in token claims"}
	}
	id, err := strconv.Atoi(uid)
	if err != nil {
		return &echo.HTTPError{Code: http.StatusBadRequest, Message: "uid param should be a valid integer"}
	}
	manager, ok := claims["manager"].(bool)
	if !ok {
		return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "wrong token or missing info in token claims"}
	}

	// If token uid is not the same as requested uid
	// only managers can change the password without knowing the old password
	if int(tokenUID) != id && !manager {
		return &echo.HTTPError{Code: http.StatusForbidden, Message: "only managers can change other users passwords"}
	}

	if int(tokenUID) == id && body.OldPassword == "" {
		return &echo.HTTPError{Code: http.StatusForbidden, Message: "the old password must be provided"}
	}

	// Check if user exists
	err = h.DB.Where("id = ?", uid).First(&dbUser).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return &echo.HTTPError{Code: http.StatusNotFound, Message: "wrong username or password"}
	}

	// Check if old passwords match
	if int(tokenUID) == id {
		if err := models.VerifyPassword(*dbUser.Password, body.OldPassword); err != nil {
			return &echo.HTTPError{Code: http.StatusForbidden, Message: "wrong old password"}
		}
	}

	// New password can't be empty
	if body.Password == "" {
		return &echo.HTTPError{Code: http.StatusForbidden, Message: "the new password must be provided"}
	}

	// If new password and old password are the same do nothing
	if int(tokenUID) == id && body.Password == body.OldPassword {
		return &echo.HTTPError{Code: http.StatusNoContent}
	}

	// New password
	hashedPassword, err := models.Hash(body.Password)
	if err != nil {
		return err
	}
	newUser["password"] = string(hashedPassword)

	// Update date
	newUser["updated_at"] = time.Now()

	// Update user
	err = h.DB.Model(&models.User{}).Where("id = ?", uid).Updates(newUser).Error
	if err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
	}

	// Return OK
	return c.NoContent(http.StatusNoContent)
}
