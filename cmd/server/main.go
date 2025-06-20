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
	db := infrastructure.NewDB(config.Persistence.PostgresSQl)

	log.Println("Server started on :3000")
	http.ListenAndServe(fmt.Sprintf(":%d", config.Server.Port), r)
}
