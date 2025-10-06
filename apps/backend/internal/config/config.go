package config

import (
	"os"
	"strings"

	"github.com/go-playground/validator/v10"
	_ "github.com/joho/godotenv/autoload"
	"github.com/knadh/koanf/providers/env"
	"github.com/knadh/koanf/v2"
	"github.com/rs/zerolog"
)

type Config struct {
	Primary Primary       `koanf:"primary" validate:"required"`
	Server  ServerConfig  `koanf:"server" validate:"required"`
	MongoDB MongoDBConfig `koanf:"mongodb" validate:"required"`
}

type Primary struct {
	Env string `koanf:"env" validate:"required"`
}

type ServerConfig struct {
	Port string `koanf:"port" validate:"required"`
}

type MongoDBConfig struct {
	URI string `koanf:"uri" validate:"required"`
}

func LoadConfig() (*Config, error) {
	logger := zerolog.New(zerolog.ConsoleWriter{Out: os.Stderr}).With().Timestamp().Logger()

	k := koanf.New(".")

	err := k.Load(env.Provider("TODO_", ".", func(s string) string {
		return strings.ToLower(strings.TrimPrefix(s, "TODO_"))
	}), nil)
	if err != nil {
		logger.Fatal().Err(err).Msg("could not load initial env variables")
	}

	mainConfig := &Config{}

	err = k.Unmarshal("", mainConfig)
	if err != nil {
		logger.Fatal().Err(err).Msg("could not unmarshal main config")
	}
	if railwayPort := os.Getenv("PORT"); railwayPort != "" {
		mainConfig.Server.Port = railwayPort
	}
	validate := validator.New()

	err = validate.Struct(mainConfig)
	if err != nil {
		logger.Fatal().Err(err).Msg("config validation failed")
	}

	return mainConfig, nil
}
