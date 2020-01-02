use std::path::PathBuf;
use itertools::Itertools;

mod lib;

const WIDTH: u8 = 25;
const HEIGHT: u8 = 6;

fn main() {
    let result: u32 = lib::spif::parse_pixels(input(), WIDTH, HEIGHT);
    println!("{}", result);
    lib::spif::render_image(input(), WIDTH, HEIGHT);
}

fn input<T: From<u32>>() -> Vec<T> {
    let file_data: String = load_file();
    file_data.chars()
        .filter_map(|c| c.to_digit(10))
        .map_into::<T>()
        .collect()
}

fn load_file() -> String {
    let path = PathBuf::from("input");
    std::fs::read_to_string(path).expect("Could not read file")
}
