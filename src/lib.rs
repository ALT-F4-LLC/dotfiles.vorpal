use vorpal_sdk::api::artifact::{
    ArtifactSystem,
    ArtifactSystem::{Aarch64Darwin, Aarch64Linux, X8664Darwin, X8664Linux},
};

pub mod file;
pub mod user;

pub const SYSTEMS: [ArtifactSystem; 4] = [Aarch64Darwin, Aarch64Linux, X8664Darwin, X8664Linux];

pub fn get_output_path(namespace: &str, digest: &str) -> String {
    format!("/var/lib/vorpal/store/artifact/output/{namespace}/{digest}")
}

#[cfg(test)]
mod tests {
    use super::get_output_path;

    #[test]
    fn output_path_is_absolute_under_the_store_namespace() {
        assert_eq!(
            get_output_path("library", "8814b4d3fa73"),
            "/var/lib/vorpal/store/artifact/output/library/8814b4d3fa73"
        );
    }
}
