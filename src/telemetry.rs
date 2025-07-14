// src/telemetry.rs
use opentelemetry::KeyValue;
use opentelemetry_otlp::WithExportConfig;
use opentelemetry_sdk::trace::Tracer;
use opentelemetry_sdk::{Resource, runtime, trace};
use tracing::Subscriber;
use tracing::subscriber::set_global_default;
use tracing_bunyan_formatter::{BunyanFormattingLayer, JsonStorageLayer};
use tracing_log::LogTracer;
use tracing_opentelemetry::OpenTelemetryLayer;
use tracing_subscriber::fmt::MakeWriter;
use tracing_subscriber::{EnvFilter, Registry, layer::SubscriberExt};

/// Sets up a new OpenTelemetry pipeline for exporting traces.
/// This pipeline sends traces to an OTLP-compatible endpoint.
fn init_trace_pipeline(otel_endpoint: &str) -> Tracer {
    // This creates a new OTLP exporter.
    // For more details, see: https://opentelemetry.io/docs/specs/otel/protocol/exporter/
    let exporter = opentelemetry_otlp::new_exporter()
        .tonic()
        .with_endpoint(otel_endpoint);

    // The tracer provider is responsible for creating tracers and managing the export pipeline.
    let tracer = opentelemetry_otlp::new_pipeline()
        .tracing()
        .with_exporter(exporter)
        .with_trace_config(
            // `service.name` is a standard attribute that helps identify your application.
            trace::config().with_resource(Resource::new(vec![KeyValue::new(
                "service.name",
                "newsletter",
            )])),
        )
        .install_batch(runtime::Tokio)
        .expect("Failed to install OTLP tracer.");

    tracer
}

/// Composes multiple layers into a `tracing`'s subscriber.
pub fn get_subscriber(
    name: String,
    env_filter: String,
    sink: impl for<'a> MakeWriter<'a> + Send + Sync + 'static,
    otel_endpoint: Option<&str>,
) -> impl Subscriber + Send + Sync {
    let env_filter =
        EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new(env_filter));

    // Layer for formatting logs into bunyan-style JSON.
    let formatting_layer = BunyanFormattingLayer::new(name, sink);

    let otel_layer = otel_endpoint.map(|endpoint| {
        let otel_tracer = init_trace_pipeline(endpoint);
        OpenTelemetryLayer::new(otel_tracer)
    });

    // The `Registry` is the foundation of the subscriber.
    // Layers are added on top of it.
    Registry::default()
        .with(env_filter)
        .with(JsonStorageLayer)
        .with(formatting_layer)
        .with(otel_layer)
}

/// Register a subscriber as global default to process span data.
pub fn init_subscriber(subscriber: impl Subscriber + Send + Sync) {
    LogTracer::init().expect("Failed to set logger");
    set_global_default(subscriber).expect("Failed to set subscriber");
}
