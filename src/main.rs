//! src/main.rs
use newsletter::configuration::get_configuration;
use newsletter::startup::run;
use newsletter::telemetry::{get_subscriber, init_subscriber};
use opentelemetry::global as opentelemetry_global;
use secrecy::ExposeSecret;
use sqlx::PgPool;
use std::net::TcpListener;

#[tokio::main]
async fn main() -> std::io::Result<()> {
    let configuration = get_configuration().expect("Failed to read configuration.");
    let subscriber = get_subscriber(
        "newsletter".into(),
        "info".into(),
        std::io::stdout,
        configuration.otel_endpoint.as_deref(),
    );
    init_subscriber(subscriber);
    let connection_pool =
        PgPool::connect(&configuration.database.connection_string().expose_secret())
            .await
            .expect("Failed to connect to Postgres.");
    let address = format!("127.0.0.1:{}", configuration.application_port);
    let listener = TcpListener::bind(address)?;
    run(listener, connection_pool)?.await?;
    opentelemetry_global::shutdown_tracer_provider();
    Ok(())
}
