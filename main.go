package main

import (
	"errors"
	"os"
	"time"

	"github.com/SlyMarbo/rss"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

type Post struct {
	URL   string    `json:"url"`
	Title string    `json:"title"`
	Date  time.Time `json:"date"`
}

func handleRequest(req events.APIGatewayProxyRequest) (interface{}, error) {
	feed, err := rss.Fetch(os.Getenv("URL"))

	if err != nil {
		return nil, errors.New("Cannot fetch RSS feed")
	}

	list := []Post{}

	for _, item := range feed.Items {
		list = append(list, Post{item.Link, item.Title, item.Date})
	}

	return list, nil
}

func main() {
	lambda.Start(handleRequest)
}
