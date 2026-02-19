package api

import (
	"encoding/json"
	"net/http"
)

func (s *APIServer) GetCameraTallyStatus(w http.ResponseWriter, r *http.Request) {
	enc := json.NewEncoder(w)
	enc.Encode(s.state.Tally)
}

func (s *APIServer) PutCameraTallyStatus(w http.ResponseWriter, r *http.Request) {
	json.NewDecoder(r.Body).Decode(&s.state.Tally)

	tally := byte(0)
	switch s.state.Tally.Status {
	case "None":
		tally = 0
	case "Program":
		tally = 1
	case "Preview":
		tally = 2
	}
	s.cam.SetTally(tally)

	s.BroadcastMessage(&WebsocketMessage{
		Type: "event",
		Data: &PropertyChanged{
			Action:   "propertyValueChanged",
			Property: "/camera/tallyStatus",
			Value:    s.state.Tally,
		},
	})

	enc := json.NewEncoder(w)
	enc.Encode(s.state.Tally)
}
