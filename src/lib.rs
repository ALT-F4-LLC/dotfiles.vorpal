use vorpal_sdk::api::artifact::{
    ArtifactSystem,
    ArtifactSystem::{Aarch64Darwin, Aarch64Linux, X8664Darwin, X8664Linux},
};

pub mod dev;
pub mod file;
pub mod user;

pub const SYSTEMS: [ArtifactSystem; 4] = [Aarch64Darwin, Aarch64Linux, X8664Darwin, X8664Linux];

pub fn get_output_path(digest: &str) -> String {
    format!("/var/lib/vorpal/store/artifact/output/{digest}")
}
