package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/workers/common/mux"
	"socialapi/workers/integration/webhook/api"

	"github.com/koding/runner"
)

var (
	Name = "IntegrationWebhook"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	redisConn := r.Bongo.MustGetRedisConn()

	iConfig := appConfig.Integration

	mc := mux.NewConfig(Name, iConfig.Host, iConfig.Port)
	m := mux.New(mc, r.Log, r.Metrics)

	h, err := api.NewHandler(appConfig, redisConn, r.Log)
	if err != nil {
		r.Log.Fatal("Could not initialize webhook worker: %s", err)
	}

	h.AddHandlers(m)

	go r.Listen()

	m.Listen()
	defer m.Close()

	r.Wait()
}
