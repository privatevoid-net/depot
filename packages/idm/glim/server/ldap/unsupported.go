package ldap

import ber "github.com/go-asn1-ber/asn1-ber"

// HandleUnsupportedOperation - TODO comment
func HandleUnsupportedOperation(message *Message) (*ber.Packet, error) {
	id := message.ID
	r := encodeExtendedResponse(id, UnwillingToPerform, "1.3.6.1.4.1.1466.20036", "")
	return r, nil
}
