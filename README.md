# PASEF-size-reducer
This R script is a custom mzML parser and cleaner, purpose-built for high-resolution mass spectrometry data — particularly for indexed mzML files generated from PASEF acquisitions (e.g., Bruker timsTOF).

PASEF-generated mzML files tend to be large in size, while the most informative content often lies in the MS2 spectra, not MS1. This script reduces file size and complexity by removing low-intensity MS1 spectral peaks below a user-defined threshold, and synchronously filters their corresponding m/z and mean inverse reduced ion mobility values to maintain data integrity.

What This Script Does
- Parses the raw XML of an **indexed mzML** file line-by-line.
- Strips the invalid `<indexList>`, `<indexListOffset>`, and `<fileChecksum>` tags that otherwise cause byte offset errors in viewers like TOPPView.
- Iterates over each `<spectrum>` block.
- For **MS1 scans only**:
  - Decodes the binary arrays: `m/z`, `intensity`, and ion mobility.
  - Filters out all peaks with intensity below a defined threshold (default: 250).
  - Applies the same filter to the corresponding `m/z` and ion mobility arrays to maintain alignment.
  - Re-encodes the filtered arrays into Base64 + zlib-compressed format.
  - Updates the `<spectrum>` metadata (e.g. `defaultArrayLength`).
- Saves a valid, cleaned, non-indexed mzML file that is compatible with most mass spec tools.


### Requirements
```r
install.packages(c("XML", "base64enc", "R.utils"))
```

### Run the script
```r
source("PASEF-size-reducer.R")

filter_mzml_by_intensity(
  input_file = "path/to/input.mzML",
  output_file = "path/to/output_filtered.mzML",
  threshold = 250  # adjust as needed
)
```

## License
MIT License. Feel free to use, adapt, and integrate into your own pipelines.
