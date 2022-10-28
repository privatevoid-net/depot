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

package db

import (
	"errors"
	"fmt"
	"os"
	"strings"

	"github.com/doncicuto/glim/models"
	"github.com/doncicuto/glim/types"
	"github.com/google/uuid"
	"github.com/sethvargo/go-password/password"
	"gorm.io/driver/postgres"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func createUsers(db *gorm.DB, dbInit types.DBInit) {
	users := dbInit.Users
	password := dbInit.DefaultPasswd

	for _, username := range strings.Split(users, ",") {
		var u models.User
		err := db.Where("username = ?", username).Take(&u).Error
		if errors.Is(err, gorm.ErrRecordNotFound) && username != "" {
			createUser(db, username, password)
		}
	}
}

func createUser(db *gorm.DB, username string, password string) {
	hash, err := models.Hash(password)
	if err != nil {
		fmt.Printf("Username: %s", "could not be created")
		return
	}

	userUUID := uuid.New().String()
	hashed := string(hash)
	manager := false
	readonly := false

	if err := db.Create(&models.User{
		Username: &username,
		Password: &hashed,
		Manager:  &manager,
		Readonly: &readonly,
		UUID:     &userUUID,
	}).Error; err != nil {
		fmt.Printf("Username: %s", "could not be created")
	}
}

func createManager(db *gorm.DB, initialPassword string) error {
	var chosenPassword string
	var err error

	if initialPassword == "" {
		chosenPassword, err = password.Generate(64, 10, 0, false, true)
		if err != nil {
			return err
		}
	} else {
		chosenPassword = initialPassword
	}

	hash, err := models.Hash(chosenPassword)
	if err != nil {
		return err
	}
	userUUID := uuid.New().String()
	username := "admin"
	firstname := "LDAP"
	lastname := "administrator"
	hashed := string(hash)
	manager := true
	readonly := false

	if err := db.Create(&models.User{
		Username:  &username,
		GivenName: &firstname,
		Surname:   &lastname,
		Password:  &hashed,
		Manager:   &manager,
		Readonly:  &readonly,
		UUID:      &userUUID,
	}).Error; err != nil {
		return err
	}

	if os.Getenv("ENV") != "test" {
		fmt.Println("")
		fmt.Println("------------------------------------- WARNING -------------------------------------")
		fmt.Println("A new user with manager permissions has been created:")
		fmt.Println("- Username: admin") // TODO - Allow username with env
		fmt.Printf("- Password %s\n", chosenPassword)
		fmt.Println("Please store or write down this password to manage Glim.")
		fmt.Println("You can delete this user once you assign manager permissions to another user")
		fmt.Println("-----------------------------------------------------------------------------------")
	}

	return nil
}

func createReadonly(db *gorm.DB, initialPassword string) error {
	var chosenPassword string
	var err error

	if initialPassword == "" {
		chosenPassword, err = password.Generate(64, 10, 0, false, true)
		if err != nil {
			return err
		}
	} else {
		chosenPassword = initialPassword
	}

	hash, err := models.Hash(chosenPassword)
	if err != nil {
		return err
	}
	userUUID := uuid.New().String()
	username := "search"
	firstname := "Read-Only"
	lastname := "Account"
	hashed := string(hash)
	manager := false
	readonly := true

	if err := db.Create(&models.User{
		Username:  &username,
		GivenName: &firstname,
		Surname:   &lastname,
		Password:  &hashed,
		Manager:   &manager,
		Readonly:  &readonly,
		UUID:      &userUUID,
	}).Error; err != nil {
		return err
	}

	if os.Getenv("ENV") != "test" {
		fmt.Println("")
		fmt.Println("------------------------------------- WARNING -------------------------------------")
		fmt.Println("A new user with read-only permissions has been created:")
		fmt.Println("- Username: search") // TODO - Allow username with env
		fmt.Printf("- Password %s\n", chosenPassword)
		fmt.Println("Please store or write down this password to perform search queries in Glim.")
		fmt.Println("-----------------------------------------------------------------------------------")
	}

	return nil
}

// Initialize - TODO common
func Initialize(dbName string, sqlLog bool, dbInit types.DBInit) (*gorm.DB, error) {
	var db *gorm.DB
	var err error
	var gormConfig = &gorm.Config{}

	// Enable sql logging
	if sqlLog {
		gormConfig.Logger = logger.Default.LogMode(logger.Info)
	} else {
		gormConfig.Logger = logger.Default.LogMode(logger.Silent)
	}

	if dbInit.UseSqlite {
		db, err = gorm.Open(sqlite.Open(dbName), gormConfig)
	} else {
		dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%d ",
			dbInit.PostgresHost,
			dbInit.PostgresUser,
			dbInit.PostgresPassword,
			dbInit.PostgresDatabase,
			dbInit.PostgresPort)

		if dbInit.PostgresSSLRootCA != "" && dbInit.PostgresSSLClientCert != "" && dbInit.PostgresSSLClientKey != "" {
			dsn += fmt.Sprintf(" sslmode=require sslrootcert=%s sslcert=%s sslkey=%s", dbInit.PostgresSSLRootCA, dbInit.PostgresSSLClientCert, dbInit.PostgresSSLClientKey)
		} else {
			dsn += " sslmode=disable"
		}
		db, err = gorm.Open(postgres.Open(dsn), gormConfig)
	}

	if err != nil {
		return nil, err
	}

	// Migrate the schema
	db.AutoMigrate(&models.User{})
	db.AutoMigrate(&models.Group{})

	// Do we have a manager? if not create one
	var manager models.User
	err = db.Where("manager = ?", true).Take(&manager).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		if err := createManager(db, dbInit.AdminPasswd); err != nil {
			return nil, err
		}
	}

	var search models.User
	err = db.Where("readonly = ?", true).Take(&search).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		if err := createReadonly(db, dbInit.SearchPasswd); err != nil {
			return nil, err
		}
	}

	createUsers(db, dbInit)

	return db, nil
}
