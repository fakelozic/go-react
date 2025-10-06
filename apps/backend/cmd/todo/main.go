package main

import (
	"context"
	"fmt"
	"log"

	"github.com/fakelozic/go-react/internal/config"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

type Todo struct {
	ID        any    `json:"id,omitempty" bson:"_id,omitempty"`
	Body      string `json:"body"`
	Completed bool   `json:"completed"`
}

var collection *mongo.Collection

func main() {
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatal("couldn't import env variables")
	}

	MONGODB_URI := cfg.MongoDB.URI

	client, err := mongo.Connect(options.Client().ApplyURI(MONGODB_URI))
	if err != nil {
		log.Fatal("database error", err)
	}
	defer func() {
		if err := client.Disconnect(context.Background()); err != nil {
			panic(err)
		}
	}()

	err = client.Ping(context.Background(), nil)
	if err != nil {
		log.Fatal("error ping mongodb", err)
	}

	fmt.Println("connected to mongodb")

	collection = client.Database("go_react_db").Collection("todos")

	app := fiber.New()

	if cfg.Primary.Env == "development" {
		app.Use(cors.New(cors.Config{
			AllowOrigins: "http://localhost:5173",
			AllowHeaders: "Origin, Content-Type, Accept",
		}))
	}

	app.Get("/api/health", func(c *fiber.Ctx) error {
		return c.Status(200).JSON(fiber.Map{"status": "ok"})
	})

	app.Get("/api/todos", listTodos)
	app.Post("/api/todos", createTodo)
	app.Get("/api/todos/:id", getTodo)
	app.Patch("/api/todos/:id", updateTodo)
	app.Delete("/api/todos/:id", deleteTodos)

	if cfg.Primary.Env == "production" {
    fmt.Println("Serving frontend in production mode")
    // This is the correct path inside the Docker container
    app.Static("/", "apps/frontend/dist")
}

	err = app.Listen(":" + cfg.Server.Port)
	if err != nil {
		log.Fatal("couldn't start the server", err)
	}
}

func listTodos(c *fiber.Ctx) error {
	cursor, err := collection.Find(context.TODO(), bson.D{})
	if err != nil {
		return err
	}
	defer cursor.Close(context.Background())
	var todos []Todo
	if err = cursor.All(context.TODO(), &todos); err != nil {
		panic(err)
	}

	return c.Status(fiber.StatusOK).JSON(todos)
}

func createTodo(c *fiber.Ctx) error {
	todo := new(Todo)
	if err := c.BodyParser(todo); err != nil {
		return err
	}
	if todo.Body == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Todo body cannot be empty"})
	}

	result, err := collection.InsertOne(context.TODO(), todo)
	if err != nil {
		return err
	}

	todo.ID = result.InsertedID
	return c.Status(fiber.StatusCreated).JSON(todo)
}

func getTodo(c *fiber.Ctx) error {
	id := c.Params("id")
	objectId, err := bson.ObjectIDFromHex(id)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid todo ID"})
	}
	filter := bson.D{{Key: "_id", Value: objectId}}
	cursor := collection.FindOne(context.TODO(), filter)
	var todo Todo
	cursor.Decode(&todo)
	if todo.Body == "" {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Todo don't exist"})
	}
	return c.Status(fiber.StatusOK).JSON(todo)
}

func updateTodo(c *fiber.Ctx) error {
	id := c.Params("id")
	objectId, err := bson.ObjectIDFromHex(id)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid todo ID"})
	}
	filter := bson.D{{Key: "_id", Value: objectId}}
	update := bson.M{"$set": bson.M{"completed": true}}

	_, err = collection.UpdateOne(context.TODO(), filter, update)
	if err != nil {
		return err
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"success": true})
}

func deleteTodos(c *fiber.Ctx) error {
	id := c.Params("id")
	objectId, err := bson.ObjectIDFromHex(id)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid todo ID"})
	}
	filter := bson.D{{Key: "_id", Value: objectId}}

	_, err = collection.DeleteOne(context.TODO(), filter)
	if err != nil {
		return err
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"success": true})
}
