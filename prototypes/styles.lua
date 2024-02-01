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
    border = {}
}