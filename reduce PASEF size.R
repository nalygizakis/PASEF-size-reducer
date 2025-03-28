library(XML)
library(base64enc)
library(R.utils)

decode_mzml_binary <- function(base64_text, compressed = TRUE) {
  raw_data <- base64decode(base64_text)
  if (compressed) raw_data <- memDecompress(raw_data, type = "gzip")
  readBin(raw_data, what = "double", endian = "little", n = length(raw_data) / 8)
}

encode_mzml_binary <- function(vec, compress = TRUE) {
  raw_vec <- writeBin(vec, raw(), endian = "little")
  if (compress) raw_vec <- memCompress(raw_vec, type = "gzip")
  base64encode(raw_vec)
}

filter_mzml_by_intensity <- function(input_file, output_file, threshold = 250) {
  doc <- xmlParse(input_file)
  spectra_nodes <- getNodeSet(doc, "//d1:spectrum", namespaces = c(d1 = "http://psi.hupo.org/ms/mzml"))
  
  for (spectrum_node in spectra_nodes) {
    ms_level_node <- getNodeSet(spectrum_node, ".//d1:cvParam[@name='ms level']", namespaces = c(d1 = "http://psi.hupo.org/ms/mzml"))
    ms_level <- as.integer(xmlGetAttr(ms_level_node[[1]], "value"))
    
    if (ms_level == 1) {
      binary_nodes <- getNodeSet(spectrum_node, ".//d1:binaryDataArray", namespaces = c(d1 = "http://psi.hupo.org/ms/mzml"))
      arrays <- list()
      
      for (binary_node in binary_nodes) {
        cv_node <- binary_node[["cvParam"]]
        type <- xmlGetAttr(cv_node, "name")
        encoded <- xmlValue(binary_node[["binary"]])
        decoded <- decode_mzml_binary(encoded)
        arrays[[type]] <- list(node = binary_node[["binary"]], data = decoded)
      }
      
      mz_data <- arrays[["m/z array"]]$data
      intensity_data <- arrays[["intensity array"]]$data
      mobility_data <- arrays[["mean inverse reduced ion mobility array"]]$data
      
      stopifnot(length(mz_data) == length(intensity_data), length(mobility_data) == length(intensity_data))
      
      keep <- intensity_data >= threshold
      
      # Apply filtering
      arrays[["m/z array"]]$data <- mz_data[keep]
      arrays[["intensity array"]]$data <- intensity_data[keep]
      arrays[["mean inverse reduced ion mobility array"]]$data <- mobility_data[keep]
      
      for (type in names(arrays)) {
        filtered <- arrays[[type]]$data
        encoded <- encode_mzml_binary(filtered)
        xmlValue(arrays[[type]]$node) <- encoded
      }
      
      # FIX: update defaultArrayLength to match filtered vector size
      new_len <- length(arrays[["m/z array"]]$data)
      xmlAttrs(spectrum_node)["defaultArrayLength"] <- as.character(new_len)
    }
  }
  
  saveXML(doc, file = output_file)
}



filter_mzml_by_intensity(
  input_file = "input_file_PASEF.mzML",
  output_file = "output_file_name_PASEF.mzML",
  threshold = 250
)
