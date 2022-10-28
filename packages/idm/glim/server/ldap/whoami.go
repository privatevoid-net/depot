package ldap

import (
	"errors"
	"fmt"

	ber "github.com/go-asn1-ber/asn1-ber"
)

// HandleExtRequest - TODO comment
func HandleExtRequest(message *Message, username string) (*ber.Packet, error) {

	id := message.ID
	p := message.Request
	n, err := requestName(p[0])
	if err != nil {
		return encodeExtendedResponse(id, err.Code, "", ""), errors.New(err.Msg)
	}

	switch n {
	case WhoamIOID:
		printLog("whoami requested by client")
		response := fmt.Sprintf("dn:%s", username)
		printLog(fmt.Sprintf("whoami response: %s", response))
		r := encodeExtendedResponse(id, Success, "", response)
		return r, nil
	default:
		printLog("unsupported extended request")
		r := encodeExtendedResponse(id, ProtocolError, "", "")
		return r, nil
	}
}
