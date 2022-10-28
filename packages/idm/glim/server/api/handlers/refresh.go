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
	"time"

	"github.com/doncicuto/glim/types"

	"github.com/doncicuto/glim/models"
	"github.com/golang-jwt/jwt"
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
)

// Refresh API tokens
// @Summary      Refresh authentication tokens
// @Description  Get new JWT access and refresh tokens
// @Tags         authentication
// @Accept       json
// @Produce      json
// @Param        tokens  body types.Tokens  true  "Access and Refresh JWT tokens"
// @Success      200  {object}  types.TokenAuthentication
// @Failure			 400  {object} types.ErrorResponse
// @Failure			 401  {object} types.ErrorResponse
// @Failure 	   500  {object} types.ErrorResponse
// @Router       /login/refresh_token [post]
func (h *Handler) Refresh(c echo.Context, settings types.APISettings) error {

	// Get refresh token from body
	tokens := new(types.Tokens)
	if err := c.Bind(tokens); err != nil {
		return &echo.HTTPError{Code: http.StatusBadRequest, Message: "could not parse token, you may have to log in again"}
	}

	// Get refresh token claims
	claims := make(jwt.MapClaims)
	token, err := jwt.ParseWithClaims(tokens.RefreshToken, claims, func(t *jwt.Token) (interface{}, error) {
		return []byte(settings.APISecret), nil
	})
	if err != nil {
		return &echo.HTTPError{Code: http.StatusBadRequest, Message: "could not parse token, you may have to log in again"}
	}

	// Check if JWT token is valid
	if !token.Valid {
		return &echo.HTTPError{Code: http.StatusBadRequest, Message: "token is not valid"}
	}

	// Extract uid
	uid, ok := claims["uid"]
	if !ok {
		return &echo.HTTPError{Code: http.StatusBadRequest, Message: "uid not found in token"}
	}

	// Extract jti
	jti, ok := claims["jti"].(string)
	if !ok {
		return &echo.HTTPError{Code: http.StatusBadRequest, Message: "jti not found in token"}
	}

	// Extract access token jti
	ajti, ok := claims["ajti"].(string)
	if !ok {
		return &echo.HTTPError{Code: http.StatusBadRequest, Message: "access jti not found in token"}
	}

	// Extract issued at time claim
	iat, ok := claims["iat"].(float64)
	if !ok {
		return &echo.HTTPError{Code: http.StatusBadRequest, Message: "iat not found in token"}
	}

	// Check if use of refresh tokens limit has been exceeded
	maxDays := settings.MaxDaysWoRelogin
	refreshLimit := time.Unix(int64(iat), 0).AddDate(0, 0, maxDays).Unix()
	if refreshLimit < time.Now().Unix() {
		return &echo.HTTPError{Code: http.StatusUnauthorized, Message: "refresh token usage without log in exceeded"}
	}

	// Check if user exists
	var dbUser models.User
	err = h.DB.Where("id = ?", uid).First(&dbUser).Error
	if err != nil {
		return &echo.HTTPError{Code: http.StatusBadRequest, Message: "invalid uid found in token"}
	}

	// Check if refresh token ID (jti) has been blacklisted
	val, found, err := h.KV.Get(jti)
	if err != nil {
		return &echo.HTTPError{Code: http.StatusBadRequest, Message: "could not get stored token info"}
	}
	if found {
		// blacklisted item?
		if string(val) == "true" {
			return &echo.HTTPError{Code: http.StatusUnauthorized, Message: "token no longer valid"}
		}
	}

	// Blacklist old refresh token
	err = h.KV.Set(jti, "true", time.Second*3600)
	if err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: "could not store refresh token info"}
	}

	// Blacklist old access token
	err = h.KV.Set(ajti, "true", time.Second*3600)
	if err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: "could not store refresh token info"}
	}

	// Prepare refresh response

	// Access token expiry time
	expiry := settings.AccessTokenExpiry
	atExpiresIn := time.Second * time.Duration(expiry)
	atExpiresOn := time.Now().Add(atExpiresIn).Unix()

	// Prepare JWT tokens common claims
	cc := jwt.MapClaims{}
	cc["iss"] = "api.glim.server"
	cc["aud"] = "api.glim.server"
	cc["sub"] = "api.glim.client"
	cc["uid"] = dbUser.ID

	// We use request token iat as the iat for new tokens
	// it will be useful to check if we have to login again
	// as the MAX_DAYS_WITHOUT_RELOGIN has been reached
	cc["iat"] = iat

	// Create access claims and token
	tokenID := uuid.New() // token id
	ac := cc              // add common claims to access token claims
	ac["jti"] = tokenID
	ac["exp"] = atExpiresOn
	ac["manager"] = dbUser.Manager
	ac["readonly"] = dbUser.Readonly
	t := jwt.New(jwt.SigningMethodHS256)
	t.Claims = ac
	at, err := t.SignedString([]byte(settings.APISecret))
	if err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: "could not create access token"}
	}

	// Add access token to Key-Value store
	err = h.KV.Set(tokenID.String(), "false", atExpiresIn)
	if err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: "could not add access token to key-value store"}
	}

	// Refresh token expiry times
	expiry = settings.RefreshTokenExpiry
	rtExpiresIn := time.Second * time.Duration(expiry)

	// Create response token
	tokenID = uuid.New() // token id
	rc := cc             // add common claims to refresh token claims
	rc["jti"] = tokenID
	rc["exp"] = time.Now().Add(rtExpiresIn).Unix()
	rc["ajti"] = ajti
	t = jwt.New(jwt.SigningMethodHS256)
	t.Claims = rc
	rt, err := t.SignedString([]byte(settings.APISecret))
	if err != nil {
		return &echo.HTTPError{Code: http.StatusInternalServerError, Message: "could not create access token"}
	}

	// Add response token to Key-Value store
	err = h.KV.Set(tokenID.String(), "false", rtExpiresIn)
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
