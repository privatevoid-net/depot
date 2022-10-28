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

	"github.com/doncicuto/glim/models"
	"github.com/golang-jwt/jwt"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

//IsReader - TODO comment
func IsReader(db *gorm.DB) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			uid := c.Param("uid")
			if c.Get("user") == nil {
				return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "wrong token or missing info in token claims"}
			}
			user := c.Get("user").(*jwt.Token)
			claims := user.Claims.(jwt.MapClaims)
			jwtID, ok := claims["uid"].(float64)
			if !ok {
				return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "wrong token or missing info in token claims"}
			}
			jwtReadonly, ok := claims["readonly"].(bool)
			if !ok {
				return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "wrong token or missing info in token claims"}
			}
			jwtManager, ok := claims["manager"].(bool)
			if !ok {
				return &echo.HTTPError{Code: http.StatusNotAcceptable, Message: "wrong token or missing info in token claims"}
			}

			if jwtManager || jwtReadonly || (uid != "" && uid == fmt.Sprintf("%d", uint(jwtID))) {
				return next(c)
			}

			// If plain user asks for her own id it's ok
			username := c.Param("username")
			var u models.User
			if username != "" {
				err := db.Where("username = ?", username).Take(&u).Error
				if err != nil {
					if errors.Is(err, gorm.ErrRecordNotFound) {
						return &echo.HTTPError{Code: http.StatusUnauthorized, Message: "user has no proper permissions"}
					}
					return &echo.HTTPError{Code: http.StatusInternalServerError, Message: err.Error()}
				} else {
					if u.ID == uint32(jwtID) {
						return next(c)
					}
				}
			}

			return &echo.HTTPError{Code: http.StatusUnauthorized, Message: "user has no proper permissions"}
		}
	}
}
