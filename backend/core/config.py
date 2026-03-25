from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_env: str
    secret_key: str
    database_url: str
    ollama_base_url: str
    ollama_model: str

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()
