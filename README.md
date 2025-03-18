Just execute

Data = importSGE2(filename)

where filename is a string containing the path and name of the SGE-2 file.
Seismic traces and their metadata are output as elements of lists. For example, Data.DATA_BLOCK is the list that contains the seismic traces, and Data.TRACE_DESCRIPTOR is the list that contains their descriptions, Data.DATA_BLOCK{i} is the i-th seismic trace array contained in DATA_BLOCK, and so on.
