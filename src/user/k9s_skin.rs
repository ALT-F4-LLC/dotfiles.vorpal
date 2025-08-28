use crate::file::FileBuilder;
use anyhow::Result;
use indoc::formatdoc;
use vorpal_sdk::{api::artifact::ArtifactSystem, context::ConfigContext};

fn format_yaml_list(colors: &[String]) -> String {
    colors
        .iter()
        .map(|color| format!("\n        - '{}'", color))
        .collect::<Vec<_>>()
        .join("")
}

pub struct K9sSkinBuilder {
    name: String,
    systems: Vec<ArtifactSystem>,
    // Body colors
    body_fg_color: String,
    body_bg_color: String,
    body_logo_color: String,
    // Prompt colors
    prompt_fg_color: String,
    prompt_bg_color: String,
    prompt_suggest_color: String,
    // Info colors
    info_fg_color: String,
    info_section_color: String,
    // Dialog colors
    dialog_fg_color: String,
    dialog_bg_color: String,
    dialog_button_fg_color: String,
    dialog_button_bg_color: String,
    dialog_button_focus_fg_color: String,
    dialog_button_focus_bg_color: String,
    dialog_label_fg_color: String,
    dialog_field_fg_color: String,
    // Frame colors
    frame_border_fg_color: String,
    frame_border_focus_color: String,
    frame_menu_fg_color: String,
    frame_menu_key_color: String,
    frame_menu_num_key_color: String,
    frame_crumbs_fg_color: String,
    frame_crumbs_bg_color: String,
    frame_crumbs_active_color: String,
    frame_status_new_color: String,
    frame_status_modify_color: String,
    frame_status_add_color: String,
    frame_status_error_color: String,
    frame_status_highlight_color: String,
    frame_status_kill_color: String,
    frame_status_completed_color: String,
    frame_title_fg_color: String,
    frame_title_bg_color: String,
    frame_title_highlight_color: String,
    frame_title_counter_color: String,
    frame_title_filter_color: String,
    // Views colors
    views_charts_bg_color: String,
    views_charts_default_dial_colors: Vec<String>,
    views_charts_default_chart_colors: Vec<String>,
    views_table_fg_color: String,
    views_table_bg_color: String,
    views_table_cursor_fg_color: String,
    views_table_cursor_bg_color: String,
    views_table_header_fg_color: String,
    views_table_header_bg_color: String,
    views_table_header_sorter_color: String,
    views_xray_fg_color: String,
    views_xray_bg_color: String,
    views_xray_cursor_color: String,
    views_xray_graphic_color: String,
    views_xray_show_icons: bool,
    views_yaml_key_color: String,
    views_yaml_colon_color: String,
    views_yaml_value_color: String,
    views_logs_fg_color: String,
    views_logs_bg_color: String,
    views_logs_indicator_fg_color: String,
    views_logs_indicator_bg_color: String,
}

impl K9sSkinBuilder {
    pub fn new(name: &str, systems: Vec<ArtifactSystem>) -> Self {
        Self {
            name: name.to_string(),
            systems,
            // Body colors
            body_fg_color: "#f8f8f2".to_string(),
            body_bg_color: "default".to_string(),
            body_logo_color: "#bd93f9".to_string(),
            // Prompt colors
            prompt_fg_color: "#f8f8f2".to_string(),
            prompt_bg_color: "default".to_string(),
            prompt_suggest_color: "#bd93f9".to_string(),
            // Info colors
            info_fg_color: "#ff79c6".to_string(),
            info_section_color: "#f8f8f2".to_string(),
            // Dialog colors
            dialog_fg_color: "#f8f8f2".to_string(),
            dialog_bg_color: "default".to_string(),
            dialog_button_fg_color: "#f8f8f2".to_string(),
            dialog_button_bg_color: "#bd93f9".to_string(),
            dialog_button_focus_fg_color: "#f1fa8c".to_string(),
            dialog_button_focus_bg_color: "#ff79c6".to_string(),
            dialog_label_fg_color: "#ffb86c".to_string(),
            dialog_field_fg_color: "#f8f8f2".to_string(),
            // Frame colors
            frame_border_fg_color: "#44475a".to_string(),
            frame_border_focus_color: "#44475a".to_string(),
            frame_menu_fg_color: "#f8f8f2".to_string(),
            frame_menu_key_color: "#ff79c6".to_string(),
            frame_menu_num_key_color: "#ff79c6".to_string(),
            frame_crumbs_fg_color: "#f8f8f2".to_string(),
            frame_crumbs_bg_color: "#44475a".to_string(),
            frame_crumbs_active_color: "#44475a".to_string(),
            frame_status_new_color: "#8be9fd".to_string(),
            frame_status_modify_color: "#bd93f9".to_string(),
            frame_status_add_color: "#50fa7b".to_string(),
            frame_status_error_color: "#ff5555".to_string(),
            frame_status_highlight_color: "#ffb86c".to_string(),
            frame_status_kill_color: "#6272a4".to_string(),
            frame_status_completed_color: "#6272a4".to_string(),
            frame_title_fg_color: "#f8f8f2".to_string(),
            frame_title_bg_color: "#44475a".to_string(),
            frame_title_highlight_color: "#ffb86c".to_string(),
            frame_title_counter_color: "#bd93f9".to_string(),
            frame_title_filter_color: "#ff79c6".to_string(),
            // Views colors
            views_charts_bg_color: "default".to_string(),
            views_charts_default_dial_colors: vec!["#bd93f9".to_string(), "#ff5555".to_string()],
            views_charts_default_chart_colors: vec!["#bd93f9".to_string(), "#ff5555".to_string()],
            views_table_fg_color: "#f8f8f2".to_string(),
            views_table_bg_color: "default".to_string(),
            views_table_cursor_fg_color: "#f8f8f2".to_string(),
            views_table_cursor_bg_color: "#44475a".to_string(),
            views_table_header_fg_color: "#f8f8f2".to_string(),
            views_table_header_bg_color: "default".to_string(),
            views_table_header_sorter_color: "#8be9fd".to_string(),
            views_xray_fg_color: "#f8f8f2".to_string(),
            views_xray_bg_color: "default".to_string(),
            views_xray_cursor_color: "#44475a".to_string(),
            views_xray_graphic_color: "#bd93f9".to_string(),
            views_xray_show_icons: false,
            views_yaml_key_color: "#ff79c6".to_string(),
            views_yaml_colon_color: "#bd93f9".to_string(),
            views_yaml_value_color: "#f8f8f2".to_string(),
            views_logs_fg_color: "#f8f8f2".to_string(),
            views_logs_bg_color: "default".to_string(),
            views_logs_indicator_fg_color: "#f8f8f2".to_string(),
            views_logs_indicator_bg_color: "#bd93f9".to_string(),
        }
    }

    // Body builder methods
    pub fn with_body_fg_color(mut self, value: &str) -> Self {
        self.body_fg_color = value.to_string();
        self
    }
    pub fn with_body_bg_color(mut self, value: &str) -> Self {
        self.body_bg_color = value.to_string();
        self
    }
    pub fn with_body_logo_color(mut self, value: &str) -> Self {
        self.body_logo_color = value.to_string();
        self
    }

    pub fn with_prompt_fg_color(mut self, value: &str) -> Self {
        self.prompt_fg_color = value.to_string();
        self
    }
    pub fn with_prompt_bg_color(mut self, value: &str) -> Self {
        self.prompt_bg_color = value.to_string();
        self
    }
    pub fn with_prompt_suggest_color(mut self, value: &str) -> Self {
        self.prompt_suggest_color = value.to_string();
        self
    }

    pub fn with_info_fg_color(mut self, value: &str) -> Self {
        self.info_fg_color = value.to_string();
        self
    }

    pub fn with_info_section_color(mut self, value: &str) -> Self {
        self.info_section_color = value.to_string();
        self
    }

    pub fn with_dialog_fg_color(mut self, value: &str) -> Self {
        self.dialog_fg_color = value.to_string();
        self
    }

    pub fn with_dialog_bg_color(mut self, value: &str) -> Self {
        self.dialog_bg_color = value.to_string();
        self
    }

    pub fn with_dialog_button_fg_color(mut self, value: &str) -> Self {
        self.dialog_button_fg_color = value.to_string();
        self
    }

    pub fn with_dialog_button_bg_color(mut self, value: &str) -> Self {
        self.dialog_button_bg_color = value.to_string();
        self
    }

    pub fn with_dialog_button_focus_fg_color(mut self, value: &str) -> Self {
        self.dialog_button_focus_fg_color = value.to_string();
        self
    }

    pub fn with_dialog_button_focus_bg_color(mut self, value: &str) -> Self {
        self.dialog_button_focus_bg_color = value.to_string();
        self
    }

    pub fn with_dialog_label_fg_color(mut self, value: &str) -> Self {
        self.dialog_label_fg_color = value.to_string();
        self
    }

    pub fn with_dialog_field_fg_color(mut self, value: &str) -> Self {
        self.dialog_field_fg_color = value.to_string();
        self
    }

    pub fn with_frame_border_fg_color(mut self, value: &str) -> Self {
        self.frame_border_fg_color = value.to_string();
        self
    }

    pub fn with_frame_border_focus_color(mut self, value: &str) -> Self {
        self.frame_border_focus_color = value.to_string();
        self
    }

    pub fn with_frame_menu_fg_color(mut self, value: &str) -> Self {
        self.frame_menu_fg_color = value.to_string();
        self
    }

    pub fn with_frame_menu_key_color(mut self, value: &str) -> Self {
        self.frame_menu_key_color = value.to_string();
        self
    }

    pub fn with_frame_menu_num_key_color(mut self, value: &str) -> Self {
        self.frame_menu_num_key_color = value.to_string();
        self
    }

    pub fn with_frame_crumbs_fg_color(mut self, value: &str) -> Self {
        self.frame_crumbs_fg_color = value.to_string();
        self
    }

    pub fn with_frame_crumbs_bg_color(mut self, value: &str) -> Self {
        self.frame_crumbs_bg_color = value.to_string();
        self
    }

    pub fn with_frame_crumbs_active_color(mut self, value: &str) -> Self {
        self.frame_crumbs_active_color = value.to_string();
        self
    }

    pub fn with_frame_status_new_color(mut self, value: &str) -> Self {
        self.frame_status_new_color = value.to_string();
        self
    }

    pub fn with_frame_status_modify_color(mut self, value: &str) -> Self {
        self.frame_status_modify_color = value.to_string();
        self
    }

    pub fn with_frame_status_add_color(mut self, value: &str) -> Self {
        self.frame_status_add_color = value.to_string();
        self
    }

    pub fn with_frame_status_error_color(mut self, value: &str) -> Self {
        self.frame_status_error_color = value.to_string();
        self
    }

    pub fn with_frame_status_highlight_color(mut self, value: &str) -> Self {
        self.frame_status_highlight_color = value.to_string();
        self
    }

    pub fn with_frame_status_kill_color(mut self, value: &str) -> Self {
        self.frame_status_kill_color = value.to_string();
        self
    }

    pub fn with_frame_status_completed_color(mut self, value: &str) -> Self {
        self.frame_status_completed_color = value.to_string();
        self
    }

    pub fn with_frame_title_fg_color(mut self, value: &str) -> Self {
        self.frame_title_fg_color = value.to_string();
        self
    }

    pub fn with_frame_title_bg_color(mut self, value: &str) -> Self {
        self.frame_title_bg_color = value.to_string();
        self
    }

    pub fn with_frame_title_highlight_color(mut self, value: &str) -> Self {
        self.frame_title_highlight_color = value.to_string();
        self
    }

    pub fn with_frame_title_counter_color(mut self, value: &str) -> Self {
        self.frame_title_counter_color = value.to_string();
        self
    }

    pub fn with_frame_title_filter_color(mut self, value: &str) -> Self {
        self.frame_title_filter_color = value.to_string();
        self
    }

    pub fn with_views_charts_bg_color(mut self, value: &str) -> Self {
        self.views_charts_bg_color = value.to_string();
        self
    }

    pub fn with_views_charts_default_dial_colors(mut self, value: Vec<String>) -> Self {
        self.views_charts_default_dial_colors = value;
        self
    }

    pub fn with_views_charts_default_chart_colors(mut self, value: Vec<String>) -> Self {
        self.views_charts_default_chart_colors = value;
        self
    }

    pub fn with_views_table_fg_color(mut self, value: &str) -> Self {
        self.views_table_fg_color = value.to_string();
        self
    }

    pub fn with_views_table_bg_color(mut self, value: &str) -> Self {
        self.views_table_bg_color = value.to_string();
        self
    }

    pub fn with_views_table_cursor_fg_color(mut self, value: &str) -> Self {
        self.views_table_cursor_fg_color = value.to_string();
        self
    }

    pub fn with_views_table_cursor_bg_color(mut self, value: &str) -> Self {
        self.views_table_cursor_bg_color = value.to_string();
        self
    }

    pub fn with_views_table_header_fg_color(mut self, value: &str) -> Self {
        self.views_table_header_fg_color = value.to_string();
        self
    }

    pub fn with_views_table_header_bg_color(mut self, value: &str) -> Self {
        self.views_table_header_bg_color = value.to_string();
        self
    }

    pub fn with_views_table_header_sorter_color(mut self, value: &str) -> Self {
        self.views_table_header_sorter_color = value.to_string();
        self
    }

    pub fn with_views_xray_fg_color(mut self, value: &str) -> Self {
        self.views_xray_fg_color = value.to_string();
        self
    }

    pub fn with_views_xray_bg_color(mut self, value: &str) -> Self {
        self.views_xray_bg_color = value.to_string();
        self
    }

    pub fn with_views_xray_cursor_color(mut self, value: &str) -> Self {
        self.views_xray_cursor_color = value.to_string();
        self
    }

    pub fn with_views_xray_graphic_color(mut self, value: &str) -> Self {
        self.views_xray_graphic_color = value.to_string();
        self
    }

    pub fn with_views_xray_show_icons(mut self, value: bool) -> Self {
        self.views_xray_show_icons = value;
        self
    }

    pub fn with_views_yaml_key_color(mut self, value: &str) -> Self {
        self.views_yaml_key_color = value.to_string();
        self
    }

    pub fn with_views_yaml_colon_color(mut self, value: &str) -> Self {
        self.views_yaml_colon_color = value.to_string();
        self
    }

    pub fn with_views_yaml_value_color(mut self, value: &str) -> Self {
        self.views_yaml_value_color = value.to_string();
        self
    }

    pub fn with_views_logs_fg_color(mut self, value: &str) -> Self {
        self.views_logs_fg_color = value.to_string();
        self
    }

    pub fn with_views_logs_bg_color(mut self, value: &str) -> Self {
        self.views_logs_bg_color = value.to_string();
        self
    }

    pub fn with_views_logs_indicator_fg_color(mut self, value: &str) -> Self {
        self.views_logs_indicator_fg_color = value.to_string();
        self
    }

    pub fn with_views_logs_indicator_bg_color(mut self, value: &str) -> Self {
        self.views_logs_indicator_bg_color = value.to_string();
        self
    }

    pub async fn build(self, context: &mut ConfigContext) -> Result<String> {
        let content = formatdoc! {r#"
                k9s:
                  # General K9s styles
                  body:
                    fgColor: '{body_fg_color}'
                    bgColor: '{body_bg_color}'
                    logoColor: '{body_logo_color}'
                  prompt:
                    fgColor: '{prompt_fg_color}'
                    bgColor: '{prompt_bg_color}'
                    suggestColor: '{prompt_suggest_color}'
                  info:
                    fgColor: '{info_fg_color}'
                    sectionColor: '{info_section_color}'
                  dialog:
                    fgColor: '{dialog_fg_color}'
                    bgColor: '{dialog_bg_color}'
                    buttonFgColor: '{dialog_button_fg_color}'
                    buttonBgColor: '{dialog_button_bg_color}'
                    buttonFocusFgColor: '{dialog_button_focus_fg_color}'
                    buttonFocusBgColor: '{dialog_button_focus_bg_color}'
                    labelFgColor: '{dialog_label_fg_color}'
                    fieldFgColor: '{dialog_field_fg_color}'
                  frame:
                    border:
                      fgColor: '{frame_border_fg_color}'
                      focusColor: '{frame_border_focus_color}'
                    menu:
                      fgColor: '{frame_menu_fg_color}'
                      keyColor: '{frame_menu_key_color}'
                      numKeyColor: '{frame_menu_num_key_color}'
                    crumbs:
                      fgColor: '{frame_crumbs_fg_color}'
                      bgColor: '{frame_crumbs_bg_color}'
                      activeColor: '{frame_crumbs_active_color}'
                    status:
                      newColor: '{frame_status_new_color}'
                      modifyColor: '{frame_status_modify_color}'
                      addColor: '{frame_status_add_color}'
                      errorColor: '{frame_status_error_color}'
                      highlightcolor: '{frame_status_highlight_color}'
                      killColor: '{frame_status_kill_color}'
                      completedColor: '{frame_status_completed_color}'
                    title:
                      fgColor: '{frame_title_fg_color}'
                      bgColor: '{frame_title_bg_color}'
                      highlightColor: '{frame_title_highlight_color}'
                      counterColor: '{frame_title_counter_color}'
                      filterColor: '{frame_title_filter_color}'
                  views:
                    charts:
                      bgColor: '{views_charts_bg_color}'
                      defaultDialColors:{charts_default_dial_colors}
                      defaultChartColors:{charts_default_chart_colors}
                    table:
                      fgColor: '{views_table_fg_color}'
                      bgColor: '{views_table_bg_color}'
                      cursorFgColor: '{views_table_cursor_fg_color}'
                      cursorBgColor: '{views_table_cursor_bg_color}'
                      header:
                        fgColor: '{views_table_header_fg_color}'
                        bgColor: '{views_table_header_bg_color}'
                        sorterColor: '{views_table_header_sorter_color}'
                    xray:
                      fgColor: '{views_xray_fg_color}'
                      bgColor: '{views_xray_bg_color}'
                      cursorColor: '{views_xray_cursor_color}'
                      graphicColor: '{views_xray_graphic_color}'
                      showIcons: {views_xray_show_icons}
                    yaml:
                      keyColor: '{views_yaml_key_color}'
                      colonColor: '{views_yaml_colon_color}'
                      valueColor: '{views_yaml_value_color}'
                    logs:
                      fgColor: '{views_logs_fg_color}'
                      bgColor: '{views_logs_bg_color}'
                      indicator:
                        fgColor: '{views_logs_indicator_fg_color}'
                        bgColor: '{views_logs_indicator_bg_color}'
            "#,
            body_fg_color = self.body_fg_color,
            body_bg_color = self.body_bg_color,
            body_logo_color = self.body_logo_color,
            prompt_fg_color = self.prompt_fg_color,
            prompt_bg_color = self.prompt_bg_color,
            prompt_suggest_color = self.prompt_suggest_color,
            info_fg_color = self.info_fg_color,
            info_section_color = self.info_section_color,
            dialog_fg_color = self.dialog_fg_color,
            dialog_bg_color = self.dialog_bg_color,
            dialog_button_fg_color = self.dialog_button_fg_color,
            dialog_button_bg_color = self.dialog_button_bg_color,
            dialog_button_focus_fg_color = self.dialog_button_focus_fg_color,
            dialog_button_focus_bg_color = self.dialog_button_focus_bg_color,
            dialog_label_fg_color = self.dialog_label_fg_color,
            dialog_field_fg_color = self.dialog_field_fg_color,
            frame_border_fg_color = self.frame_border_fg_color,
            frame_border_focus_color = self.frame_border_focus_color,
            frame_menu_fg_color = self.frame_menu_fg_color,
            frame_menu_key_color = self.frame_menu_key_color,
            frame_menu_num_key_color = self.frame_menu_num_key_color,
            frame_crumbs_fg_color = self.frame_crumbs_fg_color,
            frame_crumbs_bg_color = self.frame_crumbs_bg_color,
            frame_crumbs_active_color = self.frame_crumbs_active_color,
            frame_status_new_color = self.frame_status_new_color,
            frame_status_modify_color = self.frame_status_modify_color,
            frame_status_add_color = self.frame_status_add_color,
            frame_status_error_color = self.frame_status_error_color,
            frame_status_highlight_color = self.frame_status_highlight_color,
            frame_status_kill_color = self.frame_status_kill_color,
            frame_status_completed_color = self.frame_status_completed_color,
            frame_title_fg_color = self.frame_title_fg_color,
            frame_title_bg_color = self.frame_title_bg_color,
            frame_title_highlight_color = self.frame_title_highlight_color,
            frame_title_counter_color = self.frame_title_counter_color,
            frame_title_filter_color = self.frame_title_filter_color,
            views_charts_bg_color = self.views_charts_bg_color,
            charts_default_dial_colors = format_yaml_list(&self.views_charts_default_dial_colors),
            charts_default_chart_colors = format_yaml_list(&self.views_charts_default_chart_colors),
            views_table_fg_color = self.views_table_fg_color,
            views_table_bg_color = self.views_table_bg_color,
            views_table_cursor_fg_color = self.views_table_cursor_fg_color,
            views_table_cursor_bg_color = self.views_table_cursor_bg_color,
            views_table_header_fg_color = self.views_table_header_fg_color,
            views_table_header_bg_color = self.views_table_header_bg_color,
            views_table_header_sorter_color = self.views_table_header_sorter_color,
            views_xray_fg_color = self.views_xray_fg_color,
            views_xray_bg_color = self.views_xray_bg_color,
            views_xray_cursor_color = self.views_xray_cursor_color,
            views_xray_graphic_color = self.views_xray_graphic_color,
            views_xray_show_icons = self.views_xray_show_icons,
            views_yaml_key_color = self.views_yaml_key_color,
            views_yaml_colon_color = self.views_yaml_colon_color,
            views_yaml_value_color = self.views_yaml_value_color,
            views_logs_fg_color = self.views_logs_fg_color,
            views_logs_bg_color = self.views_logs_bg_color,
            views_logs_indicator_fg_color = self.views_logs_indicator_fg_color,
            views_logs_indicator_bg_color = self.views_logs_indicator_bg_color,
        };

        FileBuilder::new(&self.name, self.systems)
            .with_content(content.as_str())
            .build(context)
            .await
    }
}
