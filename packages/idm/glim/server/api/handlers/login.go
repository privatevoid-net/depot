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
	"time"

	"github.com/doncicuto/glim/types"
	"gorm.io/gorm"

	"github.com/doncicuto/glim/models"
	"github.com/golang-jwt/jwt"
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
)

// Login - TODO comment
// @Summary      Log in to the API
// @Description  Log in to the API and get JWT access and refresh tokens
// @Tags         authentication
// @Accept       json
// @Produce      json
// @Param        authentication  body types.LoginBody  true  "Username and password"
// @Success      200  {object}  types.TokenAuthentication
// @Failure			 400  {object} types.ErrorResponse
// @Failure			 401  {object} types.ErrorResponse
// @Failure 	   500  {object} types.ErrorResponse
// @Router       /login [post]
func (h *Handler) Login(c echo.Context, settings types.APISettings) error {
	var dbUser models.User

	// Parse username and password from body
	u := new(models.User)
	if err := c.Bind(u); err != nil {
		return &echo.HTTPError{Code: http.StatusUnauthorized, Message: "could not bind json body to user model"}
	}
	username := *u.Username
	password := *u.Password

	// Check if user exists
	err := h.DB.Where("username = ?", username).First(&dbUser).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return &echo.HTTPError{Code: http.StatusUnauthorized, Message: "wrong username or password"}
	}

	// Check if account is locked
	if *dbUser.Locked {
		return &echo.HTTPError{Code: http.StatusUnauthorized, Message: "wrong username or password"}
	}

	// Check if passwords match
	if err := models.VerifyPassword(*dbUser.Password, password); err != nil {
		return &echo.HTTPError{Code: http.StatusUnauthorized, Message: "wrong username or password"}
	}

	// Access token expiry times
	expiry := settings.AccessTokenExpiry
	atExpiresIn := time.Second * time.Duration(expiry)
	atExpiresOn := time.Now().Add(atExpiresIn).Unix()

	// Prepare JWT tokens common claims
	cc := jwt.MapClaims{}
	cc["iss"] = "api.glim.server"
	cc["aud"] = "api.glim.server"
	cc["sub"] = "api.glim.client"
	cc["uid"] = dbUser.ID
	cc["iat"] = time.Now().Unix()
	cc["exp"] = atExpiresOn

	// Create access claims and token
	ajti := uuid.New() // token id
	ac := cc           // add common claims to access token claims
	ac["jti"] = ajti
	ac["manager"] = dbUser.Manager
	ac["readonly"] = dbUser.Readonly
	t := jwt.New(jwt.SigningMethodHS256)
	t.Claims = ac
	at, err := t.SignedString([]byte(settings.APISecret))
	if err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: "could not create access token"}
	}

	// Add access token to Key-Value store
	err = h.KV.Set(ajti.String(), "false", atExpiresIn)
	if err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: "could not add access token to key-value store"}
	}

	// Refresh token expiry times
	expiry = settings.RefreshTokenExpiry
	rtExpiresIn := time.Second * time.Duration(expiry)

	// Create response token
	rjti := uuid.New() // token id
	rc := cc           // add common claims to refresh token claims
	rc["jti"] = rjti
	rc["ajti"] = ajti
	rc["exp"] = time.Now().Add(rtExpiresIn).Unix()

	t = jwt.New(jwt.SigningMethodHS256)
	t.Claims = rc
	rt, err := t.SignedString([]byte(settings.APISecret))
	if err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: "could not create access token"}
	}

	// Add response token to Key-Value store
	err = h.KV.Set(rjti.String(), "false", rtExpiresIn)
	if err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: "could not add refresh token to key-value store"}
	}

	// Create response with access and refresh tokens
	tokenAuth := types.TokenAuthentication{}
	tokenAuth.AccessToken = at
	tokenAuth.RefreshToken = rt
	tokenAuth.TokenType = "Bearer"
	tokenAuth.ExpiresIn = atExpiresIn.Seconds()
	tokenAuth.ExpiresOn = atExpiresOn

	return c.JSON(http.StatusOK, tokenAuth)
}
