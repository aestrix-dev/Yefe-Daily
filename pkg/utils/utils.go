package utils

type (
	AppSettings struct {
		Server ServerSettings      `yaml:"server"`
		DB     PersistenceSettings `yaml:"persistence"`
	}
	ServerSettings struct {
		Name string `yaml:"name"`
		Port string `yaml:"port"`
		Host string `yaml:"host"`
	}
	PersistenceSettings struct {
		PostgresSQl DBSettings `yaml:"postgres"`
	}
	DBSettings struct {
		Host          string `yaml:"host"`
		Port          string `yaml:"port"`
		ConnectionUrl string `yaml:"connection_url"`
		UserName      string `yaml:"username"`
		Password      string `yaml:"password"`
		DataBase      string `yaml:"database"`
	}
)
