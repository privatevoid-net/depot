package config

import (
	"encoding/json"
	"os"
	"testing"
)

var identityTestJSON = []byte(`{
        "id": "QmUfSFm12eYCaRdypg48m8RqkXfLW7A2ZeGZb2skeHHDGA",
        "private_key": "CAASqAkwggSkAgEAAoIBAQDpT16IRF6bb9tHsCbQ7M+nb2aI8sz8xyt8PoAWM42ki+SNoESIxKb4UhFxixKvtEdGxNE6aUUVc8kFk6wTStJ/X3IGiMetwkXiFiUxabUF/8A6SyvnSVDm+wFuavugpVrZikjLcfrf2xOVgnG3deQQvd/qbAv14jTwMFl+T+8d/cXBo8Mn/leLZCQun/EJEnkXP5MjgNI8XcWUE4NnH3E0ESSm6Pkm8MhMDZ2fmzNgqEyJ0GVinNgSml3Pyha3PBSj5LRczLip/ie4QkKx5OHvX2L3sNv/JIUHse5HSbjZ1c/4oGCYMVTYCykWiczrxBUOlcr8RwnZLOm4n2bCt5ZhAgMBAAECggEAVkePwfzmr7zR7tTpxeGNeXHtDUAdJm3RWwUSASPXgb5qKyXVsm5nAPX4lXDE3E1i/nzSkzNS5PgIoxNVU10cMxZs6JW0okFx7oYaAwgAddN6lxQtjD7EuGaixN6zZ1k/G6vT98iS6i3uNCAlRZ9HVBmjsOF8GtYolZqLvfZ5izEVFlLVq/BCs7Y5OrDrbGmn3XupfitVWYExV0BrHpobDjsx2fYdTZkmPpSSvXNcm4Iq2AXVQzoqAfGo7+qsuLCZtVlyTfVKQjMvE2ffzN1dQunxixOvev/fz4WSjGnRpC6QLn6Oqps9+VxQKqKuXXqUJC+U45DuvA94Of9MvZfAAQKBgQD7xmXueXRBMr2+0WftybAV024ap0cXFrCAu+KWC1SUddCfkiV7e5w+kRJx6RH1cg4cyyCL8yhHZ99Z5V0Mxa/b/usuHMadXPyX5szVI7dOGgIC9q8IijN7B7GMFAXc8+qC7kivehJzjQghpRRAqvRzjDls4gmbNPhbH1jUiU124QKBgQDtOaW5/fOEtOq0yWbDLkLdjImct6oKMLhENL6yeIKjMYgifzHb2adk7rWG3qcMrdgaFtDVfqv8UmMEkzk7bSkovMVj3SkLzMz84ii1SkSfyaCXgt/UOzDkqAUYB0cXMppYA7jxHa2OY8oEHdBgmyJXdLdzJxCp851AoTlRUSePgQKBgQCQgKgUHOUaXnMEx88sbOuBO14gMg3dNIqM+Ejt8QbURmI8k3arzqA4UK8Tbb9+7b0nzXWanS5q/TT1tWyYXgW28DIuvxlHTA01aaP6WItmagrphIelERzG6f1+9ib/T4czKmvROvDIHROjq8lZ7ERs5Pg4g+sbh2VbdzxWj49EQQKBgFEna36ZVfmMOs7mJ3WWGeHY9ira2hzqVd9fe+1qNKbHhx7mDJR9fTqWPxuIh/Vac5dZPtAKqaOEO8OQ6f9edLou+ggT3LrgsS/B3tNGOPvA6mNqrk/Yf/15TWTO+I8DDLIXc+lokbsogC+wU1z5NWJd13RZZOX/JUi63vTmonYBAoGBAIpglLCH2sPXfmguO6p8QcQcv4RjAU1c0GP4P5PNN3Wzo0ItydVd2LHJb6MdmL6ypeiwNklzPFwTeRlKTPmVxJ+QPg1ct/3tAURN/D40GYw9ojDhqmdSl4HW4d6gHS2lYzSFeU5jkG49y5nirOOoEgHy95wghkh6BfpwHujYJGw4"
}`)

var (
	ID         = "QmUfSFm12eYCaRdypg48m8RqkXfLW7A2ZeGZb2skeHHDGA"
	PrivateKey = "CAASqAkwggSkAgEAAoIBAQDpT16IRF6bb9tHsCbQ7M+nb2aI8sz8xyt8PoAWM42ki+SNoESIxKb4UhFxixKvtEdGxNE6aUUVc8kFk6wTStJ/X3IGiMetwkXiFiUxabUF/8A6SyvnSVDm+wFuavugpVrZikjLcfrf2xOVgnG3deQQvd/qbAv14jTwMFl+T+8d/cXBo8Mn/leLZCQun/EJEnkXP5MjgNI8XcWUE4NnH3E0ESSm6Pkm8MhMDZ2fmzNgqEyJ0GVinNgSml3Pyha3PBSj5LRczLip/ie4QkKx5OHvX2L3sNv/JIUHse5HSbjZ1c/4oGCYMVTYCykWiczrxBUOlcr8RwnZLOm4n2bCt5ZhAgMBAAECggEAVkePwfzmr7zR7tTpxeGNeXHtDUAdJm3RWwUSASPXgb5qKyXVsm5nAPX4lXDE3E1i/nzSkzNS5PgIoxNVU10cMxZs6JW0okFx7oYaAwgAddN6lxQtjD7EuGaixN6zZ1k/G6vT98iS6i3uNCAlRZ9HVBmjsOF8GtYolZqLvfZ5izEVFlLVq/BCs7Y5OrDrbGmn3XupfitVWYExV0BrHpobDjsx2fYdTZkmPpSSvXNcm4Iq2AXVQzoqAfGo7+qsuLCZtVlyTfVKQjMvE2ffzN1dQunxixOvev/fz4WSjGnRpC6QLn6Oqps9+VxQKqKuXXqUJC+U45DuvA94Of9MvZfAAQKBgQD7xmXueXRBMr2+0WftybAV024ap0cXFrCAu+KWC1SUddCfkiV7e5w+kRJx6RH1cg4cyyCL8yhHZ99Z5V0Mxa/b/usuHMadXPyX5szVI7dOGgIC9q8IijN7B7GMFAXc8+qC7kivehJzjQghpRRAqvRzjDls4gmbNPhbH1jUiU124QKBgQDtOaW5/fOEtOq0yWbDLkLdjImct6oKMLhENL6yeIKjMYgifzHb2adk7rWG3qcMrdgaFtDVfqv8UmMEkzk7bSkovMVj3SkLzMz84ii1SkSfyaCXgt/UOzDkqAUYB0cXMppYA7jxHa2OY8oEHdBgmyJXdLdzJxCp851AoTlRUSePgQKBgQCQgKgUHOUaXnMEx88sbOuBO14gMg3dNIqM+Ejt8QbURmI8k3arzqA4UK8Tbb9+7b0nzXWanS5q/TT1tWyYXgW28DIuvxlHTA01aaP6WItmagrphIelERzG6f1+9ib/T4czKmvROvDIHROjq8lZ7ERs5Pg4g+sbh2VbdzxWj49EQQKBgFEna36ZVfmMOs7mJ3WWGeHY9ira2hzqVd9fe+1qNKbHhx7mDJR9fTqWPxuIh/Vac5dZPtAKqaOEO8OQ6f9edLou+ggT3LrgsS/B3tNGOPvA6mNqrk/Yf/15TWTO+I8DDLIXc+lokbsogC+wU1z5NWJd13RZZOX/JUi63vTmonYBAoGBAIpglLCH2sPXfmguO6p8QcQcv4RjAU1c0GP4P5PNN3Wzo0ItydVd2LHJb6MdmL6ypeiwNklzPFwTeRlKTPmVxJ+QPg1ct/3tAURN/D40GYw9ojDhqmdSl4HW4d6gHS2lYzSFeU5jkG49y5nirOOoEgHy95wghkh6BfpwHujYJGw4"
)

func TestLoadJSON(t *testing.T) {
	t.Run("basic", func(t *testing.T) {
		ident := &Identity{}
		err := ident.LoadJSON(identityTestJSON)
		if err != nil {
			t.Fatal(err)
		}
	})

	loadJSON := func(t *testing.T, f func(j *identityJSON)) (*Identity, error) {
		ident := &Identity{}
		j := &identityJSON{}
		json.Unmarshal(identityTestJSON, j)
		f(j)
		tst, err := json.Marshal(j)
		if err != nil {
			return ident, err
		}
		err = ident.LoadJSON(tst)
		if err != nil {
			return ident, err
		}
		return ident, nil
	}

	t.Run("bad id", func(t *testing.T) {
		_, err := loadJSON(t, func(j *identityJSON) { j.ID = "abc" })
		if err == nil {
			t.Error("expected error decoding ID")
		}
	})

	t.Run("bad private key", func(t *testing.T) {
		_, err := loadJSON(t, func(j *identityJSON) { j.PrivateKey = "abc" })
		if err == nil {
			t.Error("expected error parsing private key")
		}
	})
}

func TestToJSON(t *testing.T) {
	ident := &Identity{}
	err := ident.LoadJSON(identityTestJSON)
	if err != nil {
		t.Fatal(err)
	}
	newjson, err := ident.ToJSON()
	if err != nil {
		t.Fatal(err)
	}
	ident2 := &Identity{}
	err = ident2.LoadJSON(newjson)
	if err != nil {
		t.Fatal(err)
	}

	if !ident.Equals(ident2) {
		t.Error("did not load to the same identity")
	}
}

func TestApplyEnvVars(t *testing.T) {
	os.Setenv("CLUSTER_ID", ID)
	os.Setenv("CLUSTER_PRIVATEKEY", PrivateKey)

	ident, err := NewIdentity()
	if err != nil {
		t.Fatal(err)
	}
	err = ident.ApplyEnvVars()
	if err != nil {
		t.Fatal(err)
	}

	ident2 := &Identity{}
	err = ident2.LoadJSON(identityTestJSON)
	if err != nil {
		t.Fatal(err)
	}

	if !ident.Equals(ident2) {
		t.Error("failed to override identity with env var")
	}
}

func TestValidate(t *testing.T) {
	ident := &Identity{}

	if ident.Validate() == nil {
		t.Fatal("expected error validating")
	}

	ident, err := NewIdentity()
	if err != nil {
		t.Fatal(err)
	}

	if ident.Validate() != nil {
		t.Error("expected to validate without error")
	}

	ident.ID = ""
	if ident.Validate() == nil {
		t.Fatal("expected error validating")
	}

}
