package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/yefe_app/server/internal/infrastructure"
	"github.com/yefe_app/server/pkg/utils"
)

func main() {
	config := utils.LoadConfig()
	_ = infrastructure.NewDB(config.Persistence.PostgresSQl)
	router := infrastructure.NewRouter()

	log.Println("Server started on :3000")
	http.ListenAndServe(fmt.Sprintf(":%d", config.Server.Port), router)
}
