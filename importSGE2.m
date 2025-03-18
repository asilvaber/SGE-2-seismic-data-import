function Data = importSGE2(filename)
% A function to import seismic traces (data blocks) from an SGE-2 file
%
% Author: Alejandro Silva, ETSIME, UPM, Spain. alejandro.silva@upm.es
%
% Inputs: filename (string, the name of the SGE-2 file containing the data)
% Outputs: Data (structure, it contains the seismic traces as data blocks and metadata)

fip = fopen(filename, 'r'); % Open file for reading
if (fip<0), disp(['Error opening ',filename]); return; end % Return if the file cannot be open
Data.FILE_DESCRIPTOR_ID = fread(fip, 1, '*uint16'); % Integer containing the file descriptor ID
if ~strcmp(dec2hex(Data.FILE_DESCRIPTOR_ID),'3A55'), disp([filename,' is not an SGE-2 file']); return; end % Check if the file follows the SGE-2 standard
Data.REVISION_NUMBER = fread(fip, 1, '*uint16'); % Revision number containing the file version
if ~strcmp(dec2hex(Data.REVISION_NUMBER),'1'), disp(['The format of ',filename,' is incompatible with this data importer']); return; end % If the revision number if not one, the file format is incompatible with this data import functon
Data.TRACE_POINTER_SUBBLOCK_SIZE = fread(fip, 1, '*uint16'); % Size of the trace pointer subblock, in bytes
if mod(Data.TRACE_POINTER_SUBBLOCK_SIZE,4)~=0, disp([filename,' is corrupted']); return; end % TRACE_POINTER_SUBBLOCK_SIZE has to be a multiple of four
Data.NUMBER_TRACES = fread(fip, 1, '*uint16'); % Total number of seismic traces contained in the file, in bytes
if Data.NUMBER_TRACES>Data.TRACE_POINTER_SUBBLOCK_SIZE/4, disp([filename,' is not a proper SGE-2 file']); return; end % TRACE_POINTER_SUBBLOCK_SIZE has to be lower than four times the parameter NUMBER_TRACES
Data.SIZE_STRING_TERMINATOR = fread(fip, 1, '*uint8'); % Size of the string terminator in the file and trace descriptor blocks, in bytes
Data.FIRST_STRING_TERMINATOR_CHAR = fread(fip, 1, '*char'); % First ASCII char of the string terminator
Data.SECOND_STRING_TERMINATOR_CHAR = fread(fip, 1, '*char'); % Second ASCII char of the string terminator
Data.SIZE_LINE_TERMINATOR = fread(fip, 1, '*uint8'); % Size of the line terminator in the file and trace descriptor blocks, in bytes
Data.FIRST_LINE_TERMINATOR_CHAR = fread(fip, 1, '*char'); % First ASCII char of the line terminator
Data.SECOND_LINE_TERMINATOR_CHAR = fread(fip, 1, '*char'); % Second ASCII char of the line terminator
for i=1:Data.NUMBER_TRACES
    fseek(fip,32+4*(i-1),'bof'); % Move pointer to the head of the i-th trace pointer
    Data.POINTER_TO_TRACE_DESCRIPTOR{i} = fread(fip, 1, '*uint32'); % Pointer to the head of the trace descriptor
    fseek(fip,Data.POINTER_TO_TRACE_DESCRIPTOR{i},'bof'); % Move pointer to the head of the i-th trace descriptor
    Data.TRACE_DESCRIPTOR_ID{i} = fread(fip, 1, '*uint16'); % Integer containing the trace descriptor ID
    if ~strcmp(dec2hex(Data.TRACE_DESCRIPTOR_ID{i}),'4422'), disp([filename,' is corrupted']); return; end % The trace descriptor ID has to be 4422 (in hex format) in all the traces
    Data.TRACE_DESCRIPTOR_BLOCK_SIZE{i} = fread(fip, 1, '*uint16'); % Size of the trace descriptor block, in bytes
    if mod(Data.TRACE_DESCRIPTOR_BLOCK_SIZE{i},4)~=0, disp([filename,' is corrupted']); return; end % TRACE_DESCRIPTOR_BLOCK_SIZE has to be a multiple of four
    Data.DATA_BLOCK_SIZE{i} = fread(fip, 1, '*uint32'); % Size of the trace data blocks, in bytes
    if mod(Data.DATA_BLOCK_SIZE{i},4)~=0, disp([filename,' is corrupted']); return; end % DATA_BLOCK_SIZE has to be a multiple of four
    Data.NUM_SAMPLES_BLOCK{i} = fread(fip, 1, '*uint32'); % Number of samples of the trace data block, in bytes
    Data.DATA_BLOCK_FORMAT{i} = fread(fip, 1, '*uint8'); % Format of the trace data block codified as an unsigned integer
    fseek(fip,Data.POINTER_TO_TRACE_DESCRIPTOR{i}+32,'bof'); % Move pointer to the head of the i-th seismic trace data block
    Data.TRACE_DESCRIPTOR{i} =  convertCharsToStrings(fread(fip, Data.TRACE_DESCRIPTOR_BLOCK_SIZE{i}-32, '*char*1')); % String containing the seismic trace descriptor
    switch Data.DATA_BLOCK_FORMAT{i} % The seismic trace data are read from the file according to the format specified by DATA_BLOCK_FORMAT
        case 1
            Data.DATA_BLOCK{i} = fread(fip, Data.NUM_SAMPLES_BLOCK{i}, '*int16');
        case 2
            Data.DATA_BLOCK{i} = fread(fip, Data.NUM_SAMPLES_BLOCK{i}, '*int32');
        case 3
            disp('File data format (20-bit floating point) is not supported by Matlab'); return;
        case 4
            Data.DATA_BLOCK{i} = fread(fip, Data.NUM_SAMPLES_BLOCK{i}, '*float32');
        case 5
            Data.DATA_BLOCK{i} = fread(fip, Data.NUM_SAMPLES_BLOCK{i}, '*float64');
        otherwise
            disp([filename,' is corrupted']); return; % Return if DATA_BLOCK_FORMAT does not match any of the predefined formats
    end
end

end