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

	"github.com/doncicuto/glim/types"
	"github.com/golang-jwt/jwt"
	"github.com/labstack/echo/v4"
)

// IsBlacklisted - TODO comment
func IsBlacklisted(kv types.Store) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			if c.Get("user") == nil {
				return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "wrong token or missing info in token claims"}
			}
			user := c.Get("user").(*jwt.Token)
			claims := user.Claims.(jwt.MapClaims)

			jti, ok := claims["jti"].(string)
			if !ok {
				return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "wrong token or missing info in token claims"}
			}

			// TODO - Review this assignment
			val, found, err := kv.Get(jti)

			if err != nil {
				return &echo.HTTPError{Code: http.StatusBadRequest, Message: "could not query the key-value store"}
			}

			if found {
				// blacklisted item
				if string(val) == "true" {
					return &echo.HTTPError{Code: http.StatusUnauthorized, Message: "token no longer valid"}
				}
			}

			return next(c)
		}
	}
}
