# Less Simple Ray Tracer

[Book 2 Final Scene](images/book2_final.png)

I built this in Odin as a means of learning a bit of Odin. I tried to follow the book closely, but there are many more differences with Odin than there was when I built this in Rust. I did get some help from LLM prompts, but mostly for troubleshooting, code search, and understanding programming theory better. 

## Unique things about the current state

- Somewhat accurate camera aperture simulation (Though I will change this in the future)
- There's some form of BVH working here, it's not great, but you can render an image in a few seconds.
- There's multithreading, but no single threading (the option will be added later)

## Goals with this project

[ ] Add CLI commands and single threaded renders
[ ] Add SDL3 integration with basic keyboard and camera controls.
[ ] Add PNG and TIFF image saving
[ ] Add debugging tools
[ ] Add GPU render pipeline
[ ] Add file loading and saving
[ ] Add better camera lens simulation
  - Camera lenses actually distort the image a lot before it gets to the sensor.
  - I want to be able to create lens stacks since most camera lenses are actually multiples stacked on one another.
  - I'd also like to simulate zoom using the lenses
  - I'd also like to add wavelength tracking so that we can also simulate IR and UV just for fun.
[ ] Refactor directory structure to be less of a headache (Odin likes things flat and specific, but that's counter too my organizational tendencies)
[ ] Optimize path tracer to be faster
