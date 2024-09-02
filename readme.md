# Festival Scheduler

The Festival Scheduler is a MATLAB project designed to automate the scheduling of shows into tracks, ensuring that no two shows on the same track overlap in time. It reads show data from a text file, schedules the shows into tracks, displays the schedule in the console, and generates a formatted HTML file.

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Input File Format](#input-file-format)
- [Output](#output)
- [Files](#files)
- [License](#license)

## Introduction

The Festival Scheduler reads a schedule of shows from an input text file, assigns each show to a non-overlapping track, and outputs the schedule in both the console and an HTML file. This tool is useful for planning events, festivals, or any scenario where multiple shows or sessions need to be scheduled without conflicts.

## Features

- Automatically schedules shows into tracks to avoid overlap.
- Outputs the schedule to the console for quick review.
- Generates a visual HTML schedule with customizable styles.
- Easy to use and configure via text input files.

## Requirements

- MATLAB R2020b or newer.
- Basic knowledge of MATLAB scripting.
- A compatible web browser to view the generated HTML output.

## Installation

1. Clone the repository:
    ```bash
    git clone https://github.com/dirkjankroon/festival.git
    ```
2. Navigate to the project directory:
    ```bash
    cd festival-scheduler
    ```

## Usage

1. Prepare your input file with the show details (see [Input File Format](#input-file-format) below).
2. Run the `schedule_festival` function from MATLAB with the required input and output file paths.

### Example:

```matlab
% Run the function with default input and output filenames
schedule_festival();

% Run the function with specified input and output filenames
schedule_festival('shows.txt', 'schedule.html');
