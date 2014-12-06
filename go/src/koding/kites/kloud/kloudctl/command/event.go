package command

import (
	"errors"
	"fmt"
	"strings"
	"time"

	"koding/kites/kloud/kloud"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

const defaultPollInterval = 4 * time.Second

type Event struct {
	event    *string
	interval *time.Duration
}

func NewEvent() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("event", "Track an event")
		f.action = &Event{
			event:    f.String("id", "", "Event id to be tracked."),
			interval: f.Duration("interval", defaultPollInterval, "Polling interval, by default 4 seconds"),
		}
		return f, nil
	}
}

func (e *Event) Action(args []string, k *kite.Client) error {
	// args[0] contains the build event in form of "build-123456"
	splitted := strings.Split(*e.event, "-")
	if len(splitted) != 2 {
		return fmt.Errorf("Incoming event data is malformed %v", *e.event)
	}

	eventType := splitted[0]
	id := splitted[1]

	return watch(k, eventType, id, *e.interval)

}

// watch watches the events of the specified event type.
func watch(k *kite.Client, eventType string, eventId string, interval time.Duration) error {
	eventArgs := kloud.EventArgs([]kloud.EventArg{
		kloud.EventArg{
			Type:    eventType,
			EventId: eventId,
		},
	})

	for {
		resp, err := k.Tell("event", eventArgs)
		if err != nil {
			return err
		}

		var events []kloud.EventResponse
		if err := resp.Unmarshal(&events); err != nil {
			return err
		}

		if len(events) == 0 {
			return errors.New("incoming event response is not an array")
		}

		DefaultUi.Info(fmt.Sprintf("%s ==> %s [Status: %s Percentage: %d]",
			fmt.Sprint(time.Now())[:19],
			events[0].Event.Message,
			events[0].Event.Status,
			events[0].Event.Percentage,
		))

		if events[0].Event.Error != "" {
			DefaultUi.Error(events[0].Event.Error)
			break
		}

		if events[0].Event.Percentage == 100 {
			break
		}

		time.Sleep(interval)
		continue // still pending
	}

	return nil
}
