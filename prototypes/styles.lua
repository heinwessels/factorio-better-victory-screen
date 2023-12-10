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