use crate::make;
use anyhow::Result;
use vorpal_sdk::context::ConfigContext;

pub struct FileBuilder {
    name: String,
    content: String,
}

impl FileBuilder {
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            content: String::new(),
        }
    }

    pub fn with_content(mut self, content: &str) -> Self {
        self.content = content.to_string();
        self
    }

    pub fn with_line(mut self, line: &str) -> Self {
        if !self.content.is_empty() {
            self.content.push('\n');
        }
        self.content.push_str(line);
        self
    }

    pub fn with_lines(mut self, lines: &[&str]) -> Self {
        for line in lines {
            self = self.with_line(line);
        }
        self
    }

    pub fn with_blank_line(mut self) -> Self {
        if !self.content.is_empty() {
            self.content.push('\n');
        }
        self.content.push('\n');
        self
    }

    pub async fn build(self, context: &mut ConfigContext) -> Result<String> {
        make::build_file(context, &self.name, &self.content).await
    }
}