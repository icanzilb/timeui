# timeui

A command line profiling tool with stopwatch, cpu and memory usage.

## Usage

`./timeui path/to/app-to-profile` runs the stopwatch and signpost regions stopwatches.

If you run `timeui` with root privileges it'll display also CPU and memory usage.

![A visual demo of timeui](https://raw.githubusercontent.com/icanzilb/timeui/main/etc/demo.gif)

The easiest way to give `timeui` a try is clone the repo and from the command line run `sudo run-demo.sh`.

## Installation

In the repo root folder run `install.sh` which builds `timeui` and copies it over into `/usr/local/bin`.

## Contributing

This tool was put in just few hours time, here's the live [twitter thread](https://twitter.com/icanzilb/status/1494577864028663810) with progress updates. 

If you'd like to improve and keep improving it, I have a list with possible steps to build it into a real, usable tool: https://github.com/icanzilb/timeui/issues

## License

Copyright (c) Marin Todorov 2022 This code is provided under the MIT License.