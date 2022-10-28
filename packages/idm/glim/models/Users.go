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

package models

import (
	"time"

	"golang.org/x/crypto/bcrypt"
)

// User - TODO comment
type User struct {
	ID           uint32    `gorm:"primary_key;auto_increment" json:"uid" csv:"uid"`
	Username     *string   `gorm:"size:64;not null;unique" json:"username" csv:"username"`
	Name         *string   `gorm:"size:300" json:"name" csv:"-"`
	GivenName    *string   `gorm:"size:150" json:"firstname" csv:"firstname"`
	Surname      *string   `gorm:"size:150" json:"lastname" csv:"lastname"`
	Email        *string   `gorm:"size:322" json:"email" csv:"email"`
	Password     *string   `gorm:"size:60" json:"password" csv:"password"`
	CreatedAt    time.Time `gorm:"default:CURRENT_TIMESTAMP" json:"created_at" csv:"-"`
	CreatedBy    *string   `gorm:"size:500" json:"created_by" csv:"-"`
	UpdatedAt    time.Time `gorm:"default:CURRENT_TIMESTAMP" json:"updated_at" csv:"-"`
	UpdatedBy    *string   `gorm:"size:500" json:"updated_by" csv:"-"`
	Manager      *bool     `gorm:"default:false" json:"manager" csv:"manager"`
	Readonly     *bool     `gorm:"default:false" json:"readonly" csv:"readonly"`
	Groups       *string   `csv:"groups"`
	MemberOf     []*Group  `gorm:"many2many:group_members" csv:"-"`
	UUID         *string   `gorm:"size:36" json:"uuid" csv:"-"`
	Locked       *bool     `gorm:"default:false" json:"locked" csv:"locked"`
	SSHPublicKey *string   `json:"ssh_public_key" csv:"ssh_public_key"`
	JPEGPhoto    *string   `json:"jpeg_photo" csv:"jpeg_photo"`
}

// JSONUserBody - TODO comment
type JSONUserBody struct {
	Username         string `json:"username"`
	Name             string `json:"name"`
	GivenName        string `json:"firstname"`
	Surname          string `json:"lastname"`
	Email            string `json:"email"`
	Password         string `json:"password"`
	SSHPublicKey     string `json:"ssh_public_key"`
	JPEGPhoto        string `json:"jpeg_photo"`
	MemberOf         string `json:"members,omitempty"`
	Manager          *bool  `json:"manager"`
	Readonly         *bool  `json:"readonly"`
	Locked           *bool  `json:"locked"`
	ReplaceMembersOf bool   `json:"replace"`
	RemoveMembersOf  bool   `json:"remove"`
}

// JSONPasswdBody - TODO comment
type JSONPasswdBody struct {
	Password    string `json:"password"`
	OldPassword string `json:"old_password"`
}

// UserInfo - TODO comment
type UserInfo struct {
	ID           uint32      `json:"uid"`
	Username     string      `json:"username"`
	Name         string      `json:"name"`
	GivenName    string      `json:"firstname"`
	Surname      string      `json:"lastname"`
	Email        string      `json:"email"`
	SSHPublicKey string      `json:"ssh_public_key"`
	JPEGPhoto    string      `json:"jpeg_photo"`
	Manager      bool        `json:"manager"`
	Readonly     bool        `json:"readonly"`
	MemberOf     []GroupInfo `json:"memberOf,omitempty"`
	Locked       bool        `json:"locked"`
}

type UserID struct {
	ID uint32 `json:"uid"`
}

// Hash - TODO comment
func Hash(password string) ([]byte, error) {
	return bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
}

// VerifyPassword - TODO comment
func VerifyPassword(hashedPassword, password string) error {
	return bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(password))
}

// GetUserInfo - TODO comment
func GetUserInfo(u User, showMemberOf bool, guacamole bool) UserInfo {
	var i UserInfo
	i.ID = u.ID
	if u.Username != nil {
		i.Username = *u.Username
	}
	if u.Name != nil {
		i.Name = *u.Name
	}
	if u.GivenName != nil {
		i.GivenName = *u.GivenName
	}
	if u.Surname != nil {
		i.Surname = *u.Surname
	}
	if u.Email != nil {
		i.Email = *u.Email
	}
	if u.SSHPublicKey != nil {
		i.SSHPublicKey = *u.SSHPublicKey
	}
	if u.JPEGPhoto != nil {
		i.JPEGPhoto = *u.JPEGPhoto
	}
	if u.Manager != nil {
		i.Manager = *u.Manager
	}
	if u.Readonly != nil {
		i.Readonly = *u.Readonly
	}
	if u.Locked != nil {
		i.Locked = *u.Locked
	}

	if showMemberOf {
		members := []GroupInfo{}
		for _, member := range u.MemberOf {
			members = append(members, *GetGroupInfo(member, !showMemberOf, guacamole))
		}
		i.MemberOf = members
	}

	return i
}
