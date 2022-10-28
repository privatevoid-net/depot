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
)

// Group - TODO comment
type Group struct {
	ID                        uint32    `gorm:"primary_key;auto_increment" json:"gid" csv:"gid"`
	Name                      *string   `gorm:"size:100;unique;not null" json:"name" csv:"name"`
	Description               *string   `gorm:"size:255" json:"description" csv:"description"`
	CreatedAt                 time.Time `gorm:"default:CURRENT_TIMESTAMP" json:"created_at" csv:"-"`
	CreatedBy                 *string   `gorm:"size:500" json:"created_by" csv:"-"`
	UpdatedAt                 time.Time `gorm:"default:CURRENT_TIMESTAMP" json:"updated_at" csv:"-"`
	UpdatedBy                 *string   `gorm:"size:500" json:"updated_by" csv:"-"`
	UUID                      *string   `gorm:"size:36" json:"uuid" csv:"-"`
	Members                   []*User   `gorm:"many2many:group_members" csv:"-"`
	GuacamoleConfigProtocol   *string   `gorm:"size:255" json:"guac_config_protocol" csv:"guac_config_protocol"`
	GuacamoleConfigParameters *string   `gorm:"size:1000" json:"guac_config_parameters" csv:"guac_config_parameters"`
	GroupMembers              *string   `csv:"members"`
}

// GroupInfo - TODO comment
type GroupInfo struct {
	ID                        uint32     `json:"gid"`
	Name                      string     `json:"name"`
	Description               string     `json:"description"`
	Members                   []UserInfo `json:"members,omitempty"`
	GuacamoleConfigProtocol   string     `json:"guac_config_protocol"`
	GuacamoleConfigParameters string     `json:"guac_config_parameters"`
}

type GroupID struct {
	ID uint32 `json:"gid"`
}

// GroupMembers - TODO comment
type GroupMembers struct {
	Members string `json:"members"`
}

// JSONGroupBody - TODO comment
type JSONGroupBody struct {
	Name                      string `json:"name"`
	Description               string `json:"description"`
	Members                   string `json:"members,omitempty"`
	ReplaceMembers            bool   `json:"replace"`
	GuacamoleConfigProtocol   string `json:"guac_config_protocol"`
	GuacamoleConfigParameters string `json:"guac_config_parameters"`
}

// GetGroupInfo - TODO comment
func GetGroupInfo(g *Group, showMembers bool, guacamole bool) *GroupInfo {
	var i GroupInfo
	i.ID = g.ID
	i.Name = *g.Name

	if g.Description != nil {
		i.Description = *g.Description
	}

	if guacamole && g.GuacamoleConfigProtocol != nil {
		i.GuacamoleConfigProtocol = *g.GuacamoleConfigProtocol
		i.GuacamoleConfigParameters = *g.GuacamoleConfigParameters
	}

	if showMembers {
		members := []UserInfo{}
		for _, member := range g.Members {
			members = append(members, GetUserInfo(*member, !showMembers, guacamole))
		}
		i.Members = members
	}

	return &i
}
