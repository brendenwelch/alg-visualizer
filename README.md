# Algorithm Visualizer

A simple sorting algorithm visualizer, implemented in Zig using [SDL3 bindings](https://github.com/Gota7/zig-sdl3). Generates a list of pseudo-random data, renders a bar graph representation of that data to a window, and applies a sorting algorithm to the data, rendering the result in real-time.


I avoided looking up the implementations to these algorithms, instead relying on the simple animations and vague descriptions available on Wikipedia. It was a challenging exercise, and getting each of these to both work and animate correctly was very satisfying. A couple improvements I'd like to make include rendering text on-screen instead of printing to the console (this was not easily possible due to the presently incomplete [SDL3 bindings](https://github.com/Gota7/zig-sdl3)), and handling both rendering and input concurrently with the main thread (sort times are much higher due to render times).

CAUTION: the first few algorithms have quadratic time complexity and will take quite a while to process. Input is not available during sorting, so you'll need to terminate manually if you don't want to wait. I've limited the dataset size, so it won't be too egregious.

## Hotkeys

- Esc => Quits the program.
- Space => Generates a new dataset.
- 1 => Bubble Sort.
- 2 => Insertion Sort.
- 3 => Comb Sort.
- 4 => Merge Sort.
- 5 => Quick Sort.
