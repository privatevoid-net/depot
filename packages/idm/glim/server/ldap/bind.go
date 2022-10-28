package ldap

import (
	"errors"
	"fmt"
	"strings"

	"github.com/doncicuto/glim/models"
	"github.com/doncicuto/glim/types"
	ber "github.com/go-asn1-ber/asn1-ber"
	"gorm.io/gorm"
)

func bindName(p *ber.Packet) (string, *ServerError) {
	if p.ClassType != ber.ClassUniversal ||
		p.TagType != ber.TypePrimitive ||
		p.Tag != ber.TagOctetString ||
		len(p.Children) != 0 {
		return "", &ServerError{
			Msg:  "wrong bind name definition",
			Code: ProtocolError,
		}
	}

	n := ber.DecodeString(p.ByteValue)
	return n, nil
}

func bindPassword(p *ber.Packet) (string, *ServerError) {
	if p.ClassType != ber.ClassContext ||
		p.TagType != ber.TypePrimitive ||
		len(p.Children) != 0 {
		return "", &ServerError{
			Msg:  "wrong authentication choice definition",
			Code: ProtocolError,
		}
	}

	if p.Tag == Sasl {
		return "", &ServerError{
			Msg:  "SASL authentication not supported",
			Code: AuthMethodNotSupported,
		}
	}

	return p.Data.String(), nil
}

// HandleBind - TODO comment
func HandleBind(message *Message, settings types.LDAPSettings, remoteAddr string) (*ber.Packet, string, error) {
	username := ""
	id := message.ID
	p := message.Request

	v, err := protocolVersion(p[0])
	if err != nil {
		return encodeBindResponse(id, err.Code, err.Msg), "", errors.New(err.Msg)
	}

	n, err := bindName(p[1])
	if err != nil {
		return encodeBindResponse(id, err.Code, err.Msg), n, errors.New(err.Msg)
	}

	pass, err := bindPassword(p[2])
	if err != nil {
		return encodeBindResponse(id, err.Code, err.Msg), n, errors.New(err.Msg)
	}

	if n == "" && pass == "" {
		return encodeBindResponse(id, InappropriateAuthentication, ""), n, fmt.Errorf("anonymous ldap bind is not available")
	}

	dn := strings.Split(n, ",")
	if strings.HasPrefix(dn[0], "cn=") {
		username = strings.TrimPrefix(dn[0], "cn=")
		domain := strings.TrimPrefix(n, dn[0])
		domain = strings.TrimPrefix(domain, ",")
		if domain != settings.Domain {
			return encodeBindResponse(id, InvalidCredentials, ""), n, fmt.Errorf("wrong domain: %s", domain)
		}
	}

	if strings.HasPrefix(dn[0], "uid=") {
		username = strings.TrimPrefix(dn[0], "uid=")
		if dn[1] != "ou=Users" {
			return encodeBindResponse(id, InvalidCredentials, ""), n, fmt.Errorf("wrong ou: %s", dn[1])
		}
		domain := strings.TrimPrefix(n, dn[0])
		domain = strings.TrimPrefix(domain, ",")
		domain = strings.TrimPrefix(domain, dn[1])
		domain = strings.TrimPrefix(domain, ",")

		if domain != settings.Domain {
			return encodeBindResponse(id, InvalidCredentials, ""), n, fmt.Errorf("wrong domain: %s", domain)
		}
	}

	// DEBUG - TODO
	printLog(fmt.Sprintf("bind protocol version: %d client %s", v, remoteAddr))
	printLog(fmt.Sprintf("bind name: %s client %s", n, remoteAddr))
	printLog(fmt.Sprintf("bind password: %s client %s", "**********", remoteAddr))

	// Check credentials in database
	var dbUser models.User

	// Check if user exists
	if errors.Is(settings.DB.Where("username = ?", username).First(&dbUser).Error, gorm.ErrRecordNotFound) {
		return encodeBindResponse(id, InsufficientAccessRights, ""), n, fmt.Errorf("wrong username or password client %s", remoteAddr)
	}

	// Check if passwords match
	if err := models.VerifyPassword(*dbUser.Password, pass); err != nil {
		return encodeBindResponse(id, InvalidCredentials, ""), n, fmt.Errorf("wrong username or password client %s", remoteAddr)
	}

	// Successful bind
	printLog("success: valid credentials provided")
	r := encodeBindResponse(id, Success, "")
	return r, n, nil
}
