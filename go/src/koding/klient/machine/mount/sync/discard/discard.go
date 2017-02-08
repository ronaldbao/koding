package discard

import (
	"sync"

	"koding/klient/machine/index"
	msync "koding/klient/machine/mount/sync"
)

// BuildOpts represents a context that can be used by external syncers to build
// their own type. Built syncer should update indexes after syncing and manage
// received events.
type BuildOpts struct {
	RemoteIdx *index.Index // known state of remote index.
	LocalIdx  *index.Index // known state of local index.
}

// DiscardBuilder is a factory for Discard synchronization objects.
type DiscardBuilder struct{}

// Build satisfies msync.Builder interface. It produces Discard objects and
// always returns nil error.
func (DiscardBuilder) Build(_ *msync.BuildOpts) (msync.Syncer, error) {
	return NewDiscard(), nil
}

// Event is a no-op for synchronization object.
type Event struct {
	ev *msync.Event
}

// Exec satisfies msync.Execer interface. The only thing this method does is
// closing internal sync event.
func (e *Event) Exec() error {
	e.ev.Done()

	return nil
}

// Discard is a no-op synchronization object. It can be used as a stub for other
// non-event-dependent logic. This means that this type should be used only in
// tests which doesn't care about mount file synchronization.
type Discard struct {
	once  sync.Once
	stopC chan struct{} // channel used to close any opened exec streams.
}

// NewDiscard creates a new Discard synchronization object.
func NewDiscard() *Discard {
	return &Discard{
		stopC: make(chan struct{}),
	}
}

// ExecStream wraps incoming msync events with discard event logic which is
// basically no-op.
func (d *Discard) ExecStream(evC <-chan *msync.Event) <-chan msync.Execer {
	exC := make(chan msync.Execer)

	go func() {
		defer close(exC)
		for {
			select {
			case ev := <-evC:
				ex := &Event{ev: ev}
				select {
				case exC <- ex:
				case <-d.stopC:
					return
				}
			case <-d.stopC:
				return
			}
		}
	}()

	return exC
}

// Close stops all created synchronization streams.
func (d *Discard) Close() {
	d.once.Do(func() {
		close(d.stopC)
	})
}
