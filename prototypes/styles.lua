local styles = data.raw["gui-style"].default

styles["bvs_frame_semitransparent"] = {
    type = "frame_style",
    graphical_set = {
        base = {
            type = "composition",
            filename = "__better-victory-screen__/graphics/semitransparent_pixel.png",
            corner_size = 1,
            position = {0, 0}
        }
    }
}

styles["bvs_finished_game_frame"] = {
    type = "frame_style",
    parent = "invisible_frame",
    graphical_set = {
        base = {
            type = "composition",
            filename = "__better-victory-screen__/graphics/finished_game_frame.png",
            corner_size = 8,
            position = {0, 0}
        }
    }
}

styles["bvs_finished_game_table"] = {
    type = "table_style",
    parent = "finished_game_table",
    border = {
        border_width = 8,
        vertical_line = {position = {0, 40}, size = {8, 1}},
        top_t = {position = {64, 40}, size = {8, 8}},
        bottom_t = {position = {48, 40}, size = {8, 8}},
    }
}

-- Some styles missing from 2.0. I'll just add them straight cause I'm lazy
styles["bvs_window_content_frame"] = {
  type = "frame_style",
  padding = 4,
  graphical_set =
  {
    base =
    {
      position = {17, 0},
      corner_size = 8,
      center = {position = {76, 8}, size = {1, 1}},
      draw_type = "outer"
    },
    shadow = default_inner_shadow
  }
}

styles["bvs_window_content_frame_packed"] = {
  type = "frame_style",
  parent = "bvs_window_content_frame",
  padding = 0,
  horizontal_flow_style =
  {
    type = "horizontal_flow_style",
    horizontal_spacing = 0
  },
  vertical_flow_style =
  {
    type = "vertical_flow_style",
    vertical_spacing = 0
  }
}

styles["bvs_finished_game_subheader_frame"] = {
  type = "frame_style",
  parent = "subheader_frame",
  left_padding = 12,
  right_padding = 12,
  bottom_padding = 5,
  top_padding = 6
}