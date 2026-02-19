package api

import (
	"encoding/json"
	"fmt"
	"net/http"
)

func (s *APIServer) GetVideoAutoExposure(w http.ResponseWriter, r *http.Request) {
	enc := json.NewEncoder(w)
	enc.Encode(s.state.AutoExposure)
}

func (s *APIServer) PutVideoAutoExposure(w http.ResponseWriter, r *http.Request) {
	fmt.Printf("GetAE %v\n", s.state.AutoExposure)

	json.NewDecoder(r.Body).Decode(&s.state.AutoExposure)

	switch s.state.AutoExposure.Mode {
	case "Off":
		s.cam.EnableAutoExposure(false)
	default:
		s.cam.EnableAutoExposure(true)
	}

	s.cam.SetExposureCompensation(s.state.AutoExposure.Compensation)
	fmt.Printf("PutAE %v\n", s.state.AutoExposure)
	s.BroadcastMessage(&WebsocketMessage{
		Type: "event",
		Data: &PropertyChanged{
			Action:   "propertyValueChanged",
			Property: "/video/autoExposure",
			Value:    s.state.AutoExposure,
		},
	})

	enc := json.NewEncoder(w)
	enc.Encode(s.state.AutoExposure)
}

func (s *APIServer) TriggerWhiteBalance(w http.ResponseWriter, r *http.Request) {
	s.cam.DoAutoWhitebalance()
	w.WriteHeader(http.StatusNoContent)
}

func (s *APIServer) PutVideoGain(w http.ResponseWriter, r *http.Request) {
	json.NewDecoder(r.Body).Decode(&s.state.Gain)

	s.cam.SetGain(uint8(s.state.Gain.Gain))
	s.BroadcastMessage(&WebsocketMessage{
		Type: "event",
		Data: &PropertyChanged{
			Action:   "propertyValueChanged",
			Property: "/video/gain",
			Value:    s.state.Gain,
		},
	})

	enc := json.NewEncoder(w)
	enc.Encode(s.state.Gain)
}

func (s *APIServer) PutVideoShutter(w http.ResponseWriter, r *http.Request) {
	json.NewDecoder(r.Body).Decode(&s.state.Shutter)

	s.cam.SetShutter(uint16(s.state.Shutter.ShutterSpeed))
	s.BroadcastMessage(&WebsocketMessage{
		Type: "event",
		Data: &PropertyChanged{
			Action:   "propertyValueChanged",
			Property: "/video/shutter",
			Value:    s.state.Shutter,
		},
	})

	enc := json.NewEncoder(w)
	enc.Encode(s.state.Shutter)
}
