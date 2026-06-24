package main

import (
	"fmt"
	"golang.org/x/text/language"
	"log"
	"os"

	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()

	for _, arg := range os.Args[1:] {
		tag, err := language.Parse(arg)
		if err != nil {
			fmt.Printf("%s: error: %v\n", arg, err)
		} else if tag == language.Und {
			fmt.Printf("%s: undefined\n", arg)
		} else {
			fmt.Printf("%s: tag %s\n", arg, tag)
		}
	}

	r.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "Hello World!",
		})
	})

	if err := r.Run(":8080"); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
