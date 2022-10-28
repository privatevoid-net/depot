package ldap

import (
	"fmt"
	"regexp"
	"strings"

	"github.com/doncicuto/glim/models"
	ber "github.com/go-asn1-ber/asn1-ber"
	"gorm.io/gorm"
)

type groupQueryParams struct {
	db             *gorm.DB
	filter         string
	originalFilter string
	attributes     string
	id             int64
	domain         string
	limit          int
	offset         int
	guacamole      bool
}

func groupEntry(group models.Group, params groupQueryParams) map[string][]string {
	attrs := make(map[string]string)
	for _, a := range strings.Split(params.attributes, " ") {
		attrs[a] = a
	}

	_, operational := attrs["+"]

	values := map[string][]string{}

	_, ok := attrs["structuralObjectClass"]
	if ok || operational {
		values["structuralObjectClass"] = []string{"groupOfNames"}
	}

	_, ok = attrs["entryUUID"]
	if ok || operational {
		values["entryUUID"] = []string{*group.UUID}
	}

	_, ok = attrs["creatorsName"]
	if ok || operational {
		creator := *group.CreatedBy
		createdBy := ""
		if creator == "admin" {
			createdBy = fmt.Sprintf("cn=admin,%s", params.domain)
		} else {
			createdBy = fmt.Sprintf("uid=%s,ou=Users,%s", creator, params.domain)
		}
		values["creatorsName"] = []string{createdBy}
	}

	_, ok = attrs["createTimestamp"]
	if ok || operational {
		values["createTimestamp"] = []string{group.CreatedAt.Format("20060102150405Z")}
	}

	_, ok = attrs["creatorsName"]
	if ok || operational {
		modifier := *group.UpdatedBy
		updatedBy := ""
		if modifier == "admin" {
			updatedBy = fmt.Sprintf("cn=admin,%s", params.domain)
		} else {
			updatedBy = fmt.Sprintf("uid=%s,ou=Users,%s", modifier, params.domain)
		}
		values["modifiersName"] = []string{updatedBy}
	}

	_, ok = attrs["modifyTimestamp"]
	if ok || operational {
		values["modifyTimestamp"] = []string{group.UpdatedAt.Format("20060102150405Z")}
	}

	if params.attributes == "ALL" || attrs["cn"] != "" || attrs["groupOfNames"] != "" || operational {
		values["cn"] = []string{*group.Name}
	}

	_, ok = attrs["objectClass"]
	if params.attributes == "ALL" || ok || operational {
		if group.GuacamoleConfigParameters != nil && group.GuacamoleConfigProtocol != nil && params.guacamole {
			values["objectClass"] = []string{"groupOfNames", "guacConfigGroup"}
		} else {
			values["objectClass"] = []string{"groupOfNames"}
		}
	}

	_, ok = attrs["entryDN"]
	if ok || operational {
		values["entryDN"] = []string{fmt.Sprintf("cn=%s,ou=Groups,%s", *group.Name, params.domain)}
	}

	_, ok = attrs["subschemaSubentry"]
	if ok || operational {
		values["subschemaSubentry"] = []string{"cn=Subschema"}
	}

	_, ok = attrs["hasSubordinates"]
	if ok || operational {
		values["hasSubordinates"] = []string{"FALSE"}
	}

	_, ok = attrs["member"]
	if params.attributes == "ALL" || ok || attrs["groupOfNames"] != "" || operational {
		members := []string{}
		for _, member := range group.Members {
			members = append(members, fmt.Sprintf("uid=%s,ou=Users,%s", *member.Username, params.domain))
		}
		values["member"] = members
	}

	_, ok = attrs["uid"]
	if params.attributes == "ALL" || ok || attrs["groupOfNames"] != "" || operational {
		uids := []string{}
		for _, member := range group.Members {
			uids = append(uids, *member.Username)
		}
		values["uid"] = uids
	}

	_, ok = attrs["guacConfigProtocol"]
	if (params.attributes == "ALL" || ok || attrs["groupOfNames"] != "" || attrs["guacConfigGroup"] != "" || operational) && params.guacamole && group.GuacamoleConfigParameters != nil && group.GuacamoleConfigProtocol != nil {
		values["guacConfigProtocol"] = []string{*group.GuacamoleConfigProtocol}
	}

	_, ok = attrs["guacConfigParameter"]
	if (params.attributes == "ALL" || ok || attrs["groupOfNames"] != "" || attrs["guacConfigGroup"] != "" || operational) && params.guacamole && group.GuacamoleConfigParameters != nil && group.GuacamoleConfigProtocol != nil {
		parameters := strings.Split(*group.GuacamoleConfigParameters, ",")
		values["guacConfigParameter"] = parameters
	}

	return values
}

func getGroupsFromDB(params groupQueryParams) ([]*ber.Packet, *ServerError, int, int64) {
	var r []*ber.Packet
	groups := []models.Group{}

	params.db = params.db.Preload("Members").Model(&models.Group{})
	analyzeGroupsCriteria(params.db, params.filter, false, "", 0, params.domain)

	allResults := params.db.Find(&groups)
	if allResults.Error != nil {
		return nil, &ServerError{
			Msg:  "could not retrieve information from database",
			Code: Other,
		}, 0, 0
	}
	totalResults := allResults.RowsAffected

	if params.limit > 0 {
		params.db.Limit(params.limit)
	}

	params.db.Offset(params.offset)

	err := params.db.Find(&groups).Error
	if err != nil {
		return nil, &ServerError{
			Msg:  "could not retrieve information from database",
			Code: Other,
		}, 0, 0
	}

	filterOutGuacConfigGroup, _ := regexp.Compile(`!\(objectClass=guacConfigGroup\)`)
	excludeGuacConfigGroup := filterOutGuacConfigGroup.FindStringSubmatch(params.originalFilter) != nil
	filterInGuacConfigGroup, _ := regexp.Compile(`&\(objectClass=guacConfigGroup\)`)
	includeGuacConfigGroup := filterInGuacConfigGroup.FindStringSubmatch(params.originalFilter) != nil

	filterUser, _ := regexp.Compile("uid=([A-Za-z.0-9-]+)")
	if filterUser.MatchString(params.originalFilter) {
		matches := filterUser.FindStringSubmatch(params.originalFilter)
		if matches != nil {
			for _, group := range groups {
				// If query contains !(objectClass=guacConfigGroup) it means that a Guacamole query has been used to exclude those groups
				if excludeGuacConfigGroup && group.GuacamoleConfigParameters != nil && group.GuacamoleConfigProtocol != nil {
					continue
				}
				filteredMembers := []*models.User{}
				for _, member := range group.Members {
					if *member.Username == matches[1] {
						// If query contains &(objectClass=guacConfigGroup) it means that a Guacamole query has been used to include those groups
						if includeGuacConfigGroup && (group.GuacamoleConfigProtocol == nil || group.GuacamoleConfigParameters == nil) {
							continue
						}
						filteredMembers = append(filteredMembers, member)
					}
				}
				if len(filteredMembers) == 0 {
					continue
				}
				group.Members = filteredMembers
				dn := fmt.Sprintf("cn=%s,ou=Groups,%s", *group.Name, params.domain)
				values := groupEntry(group, params)
				e := encodeSearchResultEntry(params.id, values, dn)
				r = append(r, e)
			}
		}
	} else {
		for _, group := range groups {
			// If query contains !(objectClass=guacConfigGroup) it means that a Guacamole query has been used to exclude those groups
			if excludeGuacConfigGroup && group.GuacamoleConfigParameters != nil && group.GuacamoleConfigProtocol != nil {
				continue
			}
			dn := fmt.Sprintf("cn=%s,ou=Groups,%s", *group.Name, params.domain)
			values := groupEntry(group, params)
			e := encodeSearchResultEntry(params.id, values, dn)
			r = append(r, e)
		}
	}

	return r, nil, len(groups), totalResults
}

func analyzeGroupsCriteria(db *gorm.DB, filter string, boolean bool, booleanOperator string, index int, domain string) {

	if boolean {

		re := regexp.MustCompile(`\(\|(.*)\)|\(\&(.*)\)|\(\!(.*)\)|\(([a-zA-Z=\ \.*]*)\)*`)
		submatchall := re.FindAllString(filter, -1)

		for index, element := range submatchall {
			element = strings.TrimPrefix(element, "(")
			element = strings.TrimSuffix(element, ")")
			analyzeGroupsCriteria(db, element, false, booleanOperator, index, domain)
		}

	} else {
		switch {
		case strings.HasPrefix(filter, "(") && strings.HasSuffix(filter, ")"):
			element := strings.TrimPrefix(filter, "(")
			element = strings.TrimSuffix(element, ")")
			analyzeGroupsCriteria(db, element, false, "", 0, domain)
		case strings.HasPrefix(filter, "&"):
			element := strings.TrimPrefix(filter, "&")
			analyzeGroupsCriteria(db, element, true, "and", 0, domain)
		case strings.HasPrefix(filter, "|"):
			element := strings.TrimPrefix(filter, "|")
			analyzeGroupsCriteria(db, element, true, "or", 0, domain)
		case strings.HasPrefix(filter, "!"):
			element := strings.TrimPrefix(filter, "!")
			analyzeGroupsCriteria(db, element, true, "not", 0, domain)
		case strings.HasPrefix(filter, "entryDN=cn=") && strings.HasSuffix(filter, fmt.Sprintf(",ou=Groups,%s", domain)):
			element := strings.TrimPrefix(filter, "entryDN=cn=")
			element = strings.TrimSuffix(element, fmt.Sprintf(",ou=Groups,%s", domain))
			if index == 0 {
				db.Where("name = ?", element)
			} else {
				db.Or("name = ?", element)
			}
		case strings.HasPrefix(filter, "cn="):
			element := strings.TrimPrefix(filter, "cn=")
			if strings.Contains(element, "*") {
				element = strings.Replace(element, "*", "%", -1)
				if index == 0 {
					db.Where("name LIKE ?", element)
				} else {
					db.Or("name LIKE ?", element)
				}
			} else {
				element = strings.Replace(element, "*", "%", -1)
				if index == 0 {
					db.Where("name = ?", element)
				} else {
					db.Or("name = ?", element)
				}
			}
		}
	}
}
